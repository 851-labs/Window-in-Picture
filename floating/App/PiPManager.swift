//
//  PiPManager.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import ScreenCaptureKit
import SwiftUI

@Observable
class PiPManager: NSObject, SCContentSharingPickerObserver {
  // Window discovery and permissions
  var availableWindows: [SCWindow] = []
  var hasPermission = false
  var isRefreshing = false

  // Stream management
  private var stream: SCStream?
  var isCapturing = false
  var selectedWindow: SCWindow?

  // Stream output
  var latestFrame: CGImage?
  private var isStreamActive = true

  // PiP window management
  var windowControllers: [PiPWindowController] = []

  // Native window picker
  private let picker = SCContentSharingPicker.shared
  private var pickerContinuation: CheckedContinuation<SCContentFilter?, Never>?

  override init() {
    super.init()
    picker.add(self)
    Task {
      await checkPermission()
      if hasPermission {
        await refreshWindows()
      }
    }
  }

  deinit {
    picker.remove(self)
  }

  // MARK: - Permissions

  func checkPermission() async {
    do {
      // Try to get shareable content to check if we have permission
      _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
      hasPermission = true
    } catch {
      print("Error checking screen recording permission: \(error)")
      hasPermission = false
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

  // MARK: - Window Discovery

  func refreshWindows() async {
    isRefreshing = true

    do {
      let content = try await SCShareableContent.excludingDesktopWindows(
        false,
        onScreenWindowsOnly: true
      )

      let windows = content.windows.filter { window in
        guard
          let app = window.owningApplication,
          let title = window.title,
          title.isEmpty == false
        else {
          return false
        }

        // Filter out our own app
        let bundleID = app.bundleIdentifier
        if bundleID == Bundle.main.bundleIdentifier {
          return false
        }

        // Filter out system UI and menubar apps by bundle ID
        if [
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
          "com.apple.wallpaper.agent",
          "com.apple.AccessibilityUIServer",
          "com.apple.Spotlight",
        ].contains(bundleID) {
          return false
        }

        // For apps without bundle IDs, filter by window title
        if bundleID.isEmpty
          && [
            "underbelly",
            "Display 1 Backstop",
            "Menubar",
            "StatusIndicator",
            "Cursor",  // This is the empty bundle ID Cursor window, not the actual Cursor editor
            "System Status Item Clone",
            "Packages Display",
          ].contains(where: { title.contains($0) })
        {
          return false
        }

        return true
      }

      availableWindows = windows
      isRefreshing = false
    } catch {
      print("Error getting available windows: \(error)")
      isRefreshing = false
    }
  }

  // MARK: - Native Window Picker

  /// Present the native window picker and create a PiP window for the selection
  func presentWindowPicker() async {
    // Configure picker to exclude our own app
    var config = SCContentSharingPickerConfiguration()
    config.excludedBundleIDs = [Bundle.main.bundleIdentifier].compactMap { $0 }
    config.allowedPickerModes = [.singleWindow]
    picker.defaultConfiguration = config

    picker.isActive = true

    let filter = await withCheckedContinuation { continuation in
      self.pickerContinuation = continuation
      picker.present()
    }

    // Create PiP window if user selected something
    if let filter = filter {
      // Try to find matching window, fall back to unique identifier
      let displayName = await findMatchingWindowDisplayName(for: filter)
        ?? "Window - \(UUID().uuidString.prefix(8))"

      let size = NSSize(
        width: filter.contentRect.width,
        height: filter.contentRect.height
      )
      createPiPWindow(with: filter, displayName: displayName, size: size)
    }
  }

  /// Try to find a matching window for the given filter by comparing frames
  private func findMatchingWindowDisplayName(for filter: SCContentFilter) async -> String? {
    // Refresh windows to get current state for matching
    await refreshWindows()

    let filterRect = filter.contentRect

    for window in availableWindows {
      if window.frame.equalTo(filterRect) {
        return window.displayName
      }
    }
    return nil
  }

  // MARK: - SCContentSharingPickerObserver

  nonisolated func contentSharingPicker(
    _ picker: SCContentSharingPicker,
    didUpdateWith filter: SCContentFilter,
    for stream: SCStream?
  ) {
    Task { @MainActor in
      pickerContinuation?.resume(returning: filter)
      pickerContinuation = nil
      picker.isActive = false
    }
  }

  nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
    Task { @MainActor in
      pickerContinuation?.resume(returning: nil)
      pickerContinuation = nil
      picker.isActive = false
    }
  }

  nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
    Task { @MainActor in
      print("Content sharing picker failed to start: \(error)")
      pickerContinuation?.resume(returning: nil)
      pickerContinuation = nil
      picker.isActive = false
    }
  }

  // MARK: - PiP Window Management

  /// Create a PiP window from an SCWindow (manual list selection)
  func createPiPWindow(for window: SCWindow) {
    // Check if we already have a PiP window for this source
    let existingController = windowControllers.first { controller in
      controller.window?.title.contains(window.displayName) ?? false
    }

    if let existingController = existingController {
      // Bring existing window to front
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new PiP window
    let controller = PiPWindowController(window: window, manager: self)
    windowControllers.append(controller)

    // Show the window
    controller.showWindow(nil)

    // Remove controller when window closes
    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: controller.window,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.windowControllers.removeAll { $0 === controller }
      }
    }
  }

  /// Create a PiP window from an SCContentFilter (native picker selection)
  func createPiPWindow(with filter: SCContentFilter, displayName: String, size: NSSize) {
    // Check if we already have a PiP window for this source
    let existingController = windowControllers.first { controller in
      controller.window?.title.contains(displayName) ?? false
    }

    if let existingController = existingController {
      // Bring existing window to front
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    // Create new PiP window
    let controller = PiPWindowController(
      filter: filter,
      displayName: displayName,
      initialSize: size,
      manager: self
    )
    windowControllers.append(controller)

    // Show the window
    controller.showWindow(nil)

    // Remove controller when window closes
    NotificationCenter.default.addObserver(
      forName: NSWindow.willCloseNotification,
      object: controller.window,
      queue: .main
    ) { [weak self] _ in
      Task { @MainActor [weak self] in
        self?.windowControllers.removeAll { $0 === controller }
      }
    }
  }

  func closeAllWindows() {
    windowControllers.forEach { $0.close() }
    windowControllers.removeAll()
  }

  // MARK: - Stream Capture

  /// Start capture for an SCWindow
  func startCapture(for window: SCWindow) async throws {
    let filter = SCContentFilter(desktopIndependentWindow: window)
    try await startCapture(with: filter, width: Int(window.frame.width), height: Int(window.frame.height))
    selectedWindow = window
  }

  /// Start capture with an SCContentFilter (from native picker)
  func startCapture(with filter: SCContentFilter) async throws {
    // Use content rect from filter for dimensions
    let width = Int(filter.contentRect.width)
    let height = Int(filter.contentRect.height)
    try await startCapture(with: filter, width: width, height: height)
  }

  private func startCapture(with filter: SCContentFilter, width: Int, height: Int) async throws {
    // If already capturing, stop the existing capture first
    if isCapturing {
      await stopCapture()
      // Small delay to ensure cleanup completes
      try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
    }

    isStreamActive = true

    // Configure stream
    let streamConfig = SCStreamConfiguration()
    streamConfig.width = width
    streamConfig.height = height

    streamConfig.showsCursor = false
    streamConfig.capturesAudio = false

    streamConfig.ignoreShadowsDisplay = true
    streamConfig.ignoreGlobalClipDisplay = true
    streamConfig.ignoreGlobalClipSingleWindow = true

    // Create stream
    stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)

    // Add self as stream output
    try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)

    // Start capture
    try await stream?.startCapture()
    isCapturing = true
  }

  func stopCapture() async {
    guard isCapturing else { return }

    do {
      // First stop the capture
      try await stream?.stopCapture()

      // Deactivate the stream
      isStreamActive = false
      latestFrame = nil

      // Remove self as stream output before clearing references
      if let stream = stream {
        try stream.removeStreamOutput(self, type: .screen)
      }

      // Clear all references
      stream = nil
      isCapturing = false
      selectedWindow = nil
    } catch {
      print("Error stopping capture: \(error)")
      // Even if there's an error, deactivate and clear the references
      isStreamActive = false
      latestFrame = nil
      stream = nil
      isCapturing = false
      selectedWindow = nil
    }
  }
}

// MARK: - SCStreamOutput

extension PiPManager: SCStreamOutput {
  func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard isStreamActive,
      type == .screen,
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }

    // Create CGImage from the sample buffer
    let ciImage = CIImage(cvPixelBuffer: imageBuffer)
    let context = CIContext()

    if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
      Task { @MainActor in
        if self.isStreamActive {
          self.latestFrame = cgImage
        }
      }
    }
  }

  func stream(_ stream: SCStream, didStopWithError error: Error) {
    print("Stream stopped with error: \(error)")
    Task { @MainActor in
      self.isStreamActive = false
      self.latestFrame = nil
    }
  }
}
