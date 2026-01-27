import AppKit
import Observation
import ScreenCaptureKit

@MainActor
@Observable
class PiPManager: NSObject {
  var availableWindows: [SCWindow] = []
  var hasPermission = false
  var isRefreshing = false

  var isCapturing = false
  var selectedWindow: SCWindow?
  var latestFrame: CGImage?

  private var stream: SCStream?
  private var isStreamActive = true
  private var windowControllers: [PiPWindowController] = []
  private let picker = SCContentSharingPicker.shared
  private var pickerContinuation: CheckedContinuation<SCContentFilter?, Never>?

  override init() {
    super.init()
    picker.add(self)
  }

  deinit {
    picker.remove(self)
  }
}

// MARK: - Permissions

extension PiPManager {
  func checkPermission() async {
    do {
      _ = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
      hasPermission = true
    } catch {
      print("Error checking screen recording permission: \(error)")
      hasPermission = false
    }
  }

  func requestPermission() async {
    await checkPermission()
    if hasPermission {
      await refreshWindows()
    }
  }
}

// MARK: - Window Discovery

extension PiPManager {
  func refreshWindows() async {
    isRefreshing = true
    defer { isRefreshing = false }

    do {
      let content = try await SCShareableContent.excludingDesktopWindows(
        false,
        onScreenWindowsOnly: true
      )
      availableWindows = content.windows.filter(shouldIncludeWindow)
    } catch {
      print("Error getting available windows: \(error)")
    }
  }

  private func shouldIncludeWindow(_ window: SCWindow) -> Bool {
    guard
      let app = window.owningApplication,
      let title = window.title,
      title.isEmpty == false
    else {
      return false
    }

    let bundleID = app.bundleIdentifier
    if bundleID == Bundle.main.bundleIdentifier {
      return false
    }

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

    if bundleID.isEmpty
      && [
        "underbelly",
        "Backstop",
        "Menubar",
        "StatusIndicator",
        "Cursor",
        "System Status Item Clone",
        "Packages Display",
      ].contains(where: { title.contains($0) })
    {
      return false
    }

    return true
  }
}

// MARK: - Native Window Picker

extension PiPManager {
  func presentWindowPicker() async {
    var config = SCContentSharingPickerConfiguration()
    config.excludedBundleIDs = [Bundle.main.bundleIdentifier].compactMap { $0 }
    config.allowedPickerModes = [.singleWindow]
    picker.defaultConfiguration = config

    picker.isActive = true

    let filter = await withCheckedContinuation { continuation in
      pickerContinuation = continuation
      picker.present()
    }

    if let filter = filter {
      let displayName = await findMatchingWindowDisplayName(for: filter)
        ?? "Window - \(UUID().uuidString.prefix(8))"
      let size = NSSize(width: filter.contentRect.width, height: filter.contentRect.height)
      createPiPWindow(with: filter, displayName: displayName, size: size)
    }
  }

  private func findMatchingWindowDisplayName(for filter: SCContentFilter) async -> String? {
    await refreshWindows()

    let filterRect = filter.contentRect
    for window in availableWindows where window.frame.equalTo(filterRect) {
      return windowDisplayName(window)
    }
    return nil
  }

  private func windowDisplayName(_ window: SCWindow) -> String {
    if let appName = window.owningApplication?.applicationName,
      let windowTitle = window.title
    {
      return "\(appName) - \(windowTitle)"
    }
    return window.title ?? "Unknown Window"
  }
}

// MARK: - SCContentSharingPickerObserver

extension PiPManager: SCContentSharingPickerObserver {
  nonisolated func contentSharingPicker(
    _ picker: SCContentSharingPicker,
    didUpdateWith filter: SCContentFilter,
    for stream: SCStream?
  ) {
    Task { @MainActor in
      pickerContinuation?.resume(returning: filter)
      pickerContinuation = nil
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
}

// MARK: - PiP Window Management

extension PiPManager {
  func createPiPWindow(for window: SCWindow) {
    let windowName = windowDisplayName(window)
    let existingController = windowControllers.first { controller in
      controller.window?.title.contains(windowName) ?? false
    }

    if let existingController = existingController {
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    let controller = PiPWindowController(window: window, displayName: windowName, manager: self)
    windowControllers.append(controller)
    controller.showWindow(nil)

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

  func createPiPWindow(with filter: SCContentFilter, displayName: String, size: NSSize) {
    let existingController = windowControllers.first { controller in
      controller.window?.title.contains(displayName) ?? false
    }

    if let existingController = existingController {
      existingController.window?.makeKeyAndOrderFront(nil)
      return
    }

    let controller = PiPWindowController(
      filter: filter,
      displayName: displayName,
      initialSize: size,
      manager: self
    )
    windowControllers.append(controller)
    controller.showWindow(nil)

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
}

// MARK: - Stream Capture

extension PiPManager {
  func startCapture(for window: SCWindow) async throws {
    let filter = SCContentFilter(desktopIndependentWindow: window)
    try await startCapture(with: filter, width: Int(window.frame.width), height: Int(window.frame.height))
    selectedWindow = window
  }

  func startCapture(with filter: SCContentFilter) async throws {
    let width = Int(filter.contentRect.width)
    let height = Int(filter.contentRect.height)
    try await startCapture(with: filter, width: width, height: height)
  }

  private func startCapture(with filter: SCContentFilter, width: Int, height: Int) async throws {
    if isCapturing {
      await stopCapture()
      try await Task.sleep(nanoseconds: 100_000_000)
    }

    isStreamActive = true

    let streamConfig = SCStreamConfiguration()
    streamConfig.width = width
    streamConfig.height = height
    streamConfig.showsCursor = false
    streamConfig.capturesAudio = false
    streamConfig.ignoreShadowsDisplay = true
    streamConfig.ignoreGlobalClipDisplay = true
    streamConfig.ignoreGlobalClipSingleWindow = true

    stream = SCStream(filter: filter, configuration: streamConfig, delegate: nil)
    try stream?.addStreamOutput(self, type: .screen, sampleHandlerQueue: .main)
    try await stream?.startCapture()
    isCapturing = true
  }

  func stopCapture() async {
    guard isCapturing else { return }

    picker.isActive = false

    do {
      try await stream?.stopCapture()
      isStreamActive = false
      latestFrame = nil

      if let stream = stream {
        try stream.removeStreamOutput(self, type: .screen)
      }

      stream = nil
      isCapturing = false
      selectedWindow = nil
    } catch {
      print("Error stopping capture: \(error)")
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
  nonisolated func stream(
    _ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer,
    of type: SCStreamOutputType
  ) {
    guard type == .screen,
      let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
    else { return }

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

  nonisolated func stream(_ stream: SCStream, didStopWithError error: Error) {
    print("Stream stopped with error: \(error)")
    Task { @MainActor in
      self.isStreamActive = false
      self.latestFrame = nil
    }
  }
}
