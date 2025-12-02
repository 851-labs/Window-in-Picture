//
//  WindowSelector.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import ScreenCaptureKit
import SwiftUI

/// Window selector using macOS native SCContentSharingPicker
@MainActor
class WindowSelector: NSObject, SCContentSharingPickerObserver {
  private var continuation: CheckedContinuation<SCContentFilter?, Never>?
  private let picker = SCContentSharingPicker.shared

  override init() {
    super.init()
    picker.add(self)
  }

  deinit {
    picker.remove(self)
  }

  /// Present the native content sharing picker and return the selected content filter
  func selectContent() async -> SCContentFilter? {
    // Configure picker to exclude our own app
    var config = SCContentSharingPickerConfiguration()
    config.excludedBundleIDs = [Bundle.main.bundleIdentifier].compactMap { $0 }
    config.allowedPickerModes = [.singleWindow]
    picker.defaultConfiguration = config

    picker.isActive = true

    return await withCheckedContinuation { continuation in
      self.continuation = continuation
      picker.present()
    }
  }

  // MARK: - SCContentSharingPickerObserver

  nonisolated func contentSharingPicker(
    _ picker: SCContentSharingPicker,
    didUpdateWith filter: SCContentFilter,
    for stream: SCStream?
  ) {
    Task { @MainActor in
      continuation?.resume(returning: filter)
      continuation = nil
      picker.isActive = false
    }
  }

  nonisolated func contentSharingPicker(_ picker: SCContentSharingPicker, didCancelFor stream: SCStream?) {
    Task { @MainActor in
      continuation?.resume(returning: nil)
      continuation = nil
      picker.isActive = false
    }
  }

  nonisolated func contentSharingPickerStartDidFailWithError(_ error: Error) {
    Task { @MainActor in
      print("Content sharing picker failed to start: \(error)")
      continuation?.resume(returning: nil)
      continuation = nil
      picker.isActive = false
    }
  }
}
