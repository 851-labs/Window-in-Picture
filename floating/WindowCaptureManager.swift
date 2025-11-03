//
//  WindowCaptureManager.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import Combine
import Foundation
import Observation
import ScreenCaptureKit
import SwiftUI

@Observable
class WindowCaptureManager {
  var availableWindows: [SCWindow] = []
  var hasPermission = false
  var isRefreshing = false
  var selectedWindow: SCWindow?

  private var stream: SCStream?
  private var streamOutput: CaptureStreamOutput?
  var isCapturing = false

  init() {
    Task {
      await checkPermission()
      if hasPermission {
        await refreshWindows()
      }
    }
  }

  func checkPermission() async {
    do {
      // Try to get shareable content to check if we have permission
      _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
      await MainActor.run {
        self.hasPermission = true
      }
    } catch {
      print("Error checking screen recording permission: \(error)")
      await MainActor.run {
        self.hasPermission = false
      }
    }
  }

  func requestPermission() async {
    // On macOS, we can't directly request permission - the system will prompt when we try to use the API
    // Just try to access content which will trigger the system prompt if needed
    await checkPermission()
    if hasPermission {
      await refreshWindows()
    }
  }

  func refreshWindows() async {
    await MainActor.run {
      isRefreshing = true
    }

    do {
      let content = try await SCShareableContent.excludingDesktopWindows(
        false,
        onScreenWindowsOnly: true
      )

      let windows = content.windows.filter { window in
        guard let app = window.owningApplication,
          let title = window.title,
          !title.isEmpty,
          window.isOnScreen
        else { return false }

        // Filter out our own app
        let bundleID = app.bundleIdentifier
        if bundleID == Bundle.main.bundleIdentifier { return false }

        // Filter out system UI and menubar apps
        let excludedBundleIDs = [
          "com.apple.controlcenter",
          "com.apple.notificationcenterui",
          "com.apple.systemuiserver",
          "com.apple.dock",
          "com.apple.WindowManager",
          "com.apple.screencaptureui",
          "com.apple.screenshot.window",
          "com.apple.TextInputMenuAgent",
          "com.apple.TextInputSwitcher",
          "com.apple.finder.Open-With-Pro",
          "com.apple.AirPlayUIAgent",
          "com.apple.WiFiAgent",
          "com.apple.BluetoothUIService",
        ]

        if excludedBundleIDs.contains(bundleID) { return false }

        // Filter out menubar apps (they typically have no proper window title or specific patterns)
        let excludedAppNames = [
          "Control Center",
          "Notification Center",
          "Screenshot",
          "Window Server",
          "SystemUIServer",
          "Dock",
          "Spotlight",
          "Siri",
        ]

        // Also check for common menubar app patterns in bundle IDs
        let menubarPatterns = ["statusitem", "menubar", "agent", "helper", "menu"]
        if menubarPatterns.contains(where: { bundleID.lowercased().contains($0) }) {
          // But allow some legitimate apps that might have these terms
          let allowedBundleIDs = ["com.apple.TextEdit", "com.microsoft.VSCode"]
          if !allowedBundleIDs.contains(bundleID) {
            return false
          }
        }

        if excludedAppNames.contains(app.applicationName) { return false }

        // Filter out windows that look like menubar popups or system windows
        // These often have very small heights or specific frame characteristics
        if window.frame.height < 50 && window.frame.width < 300 { return false }

        // Filter out windows with generic system-like titles
        let excludedTitles = ["Item-0", "Focus", "Menubar", "Menu Bar"]
        if excludedTitles.contains(where: { title.contains($0) }) { return false }

        return true
      }

      await MainActor.run {
        self.availableWindows = windows
        self.isRefreshing = false
      }
    } catch {
      print("Error getting available windows: \(error)")
      await MainActor.run {
        self.isRefreshing = false
      }
    }
  }

  func startCapture(for window: SCWindow, streamOutput: CaptureStreamOutput) async throws {
    // If already capturing, stop the existing capture first
    if isCapturing {
      await stopCapture()
      // Small delay to ensure cleanup completes
      try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }

    selectedWindow = window
    self.streamOutput = streamOutput

    // Create content filter for the specific window
    let filter = SCContentFilter(desktopIndependentWindow: window)

    // Configure stream
    let streamConfig = SCStreamConfiguration()
    streamConfig.width = Int(window.frame.width)
    streamConfig.height = Int(window.frame.height)
    streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: 30)  // 30 FPS
    streamConfig.queueDepth = 5
    streamConfig.pixelFormat = kCVPixelFormatType_32BGRA
    streamConfig.showsCursor = true
    streamConfig.capturesAudio = false

    // Create stream
    stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)

    // Add stream output
    try stream?.addStreamOutput(streamOutput, type: .screen, sampleHandlerQueue: .main)

    // Start capture
    try await stream?.startCapture()
    isCapturing = true
  }

  func stopCapture() async {
    guard isCapturing else { return }

    do {
      // First stop the capture
      try await stream?.stopCapture()

      // Deactivate the stream output
      streamOutput?.deactivate()

      // Remove the stream output before clearing references
      if let stream = stream, let output = streamOutput {
        try stream.removeStreamOutput(output, type: .screen)
      }

      // Clear all references
      stream = nil
      streamOutput = nil
      isCapturing = false
      selectedWindow = nil
    } catch {
      print("Error stopping capture: \(error)")
      // Even if there's an error, deactivate and clear the references
      streamOutput?.deactivate()
      stream = nil
      streamOutput = nil
      isCapturing = false
      selectedWindow = nil
    }
  }
}

// Stream output handler
@Observable
class CaptureStreamOutput: NSObject, SCStreamOutput {
  var latestFrame: CGImage?
  private var isActive = true

  func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard isActive,
      type == .screen,
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }

    // Create CGImage from the sample buffer
    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
    let context = CIContext()

    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
      Task { @MainActor in
        if self.isActive {
          self.latestFrame = cgImage
        }
      }
    }
  }

  func stream(_ stream: SCStream, didStopWithError error: Error) {
    print("Stream stopped with error: \(error)")
    Task { @MainActor in
      self.isActive = false
      self.latestFrame = nil
    }
  }

  func deactivate() {
    isActive = false
    latestFrame = nil
  }
}

// Window info for display
extension SCWindow {
  var displayName: String {
    if let appName = owningApplication?.applicationName,
      let windowTitle = title
    {
      return "\(appName) - \(windowTitle)"
    }
    return title ?? "Unknown Window"
  }

  var appIcon: NSImage? {
    guard let bundleID = owningApplication?.bundleIdentifier else { return nil }
    return NSWorkspace.shared.icon(
      forFile: NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path ?? "")
  }
}
