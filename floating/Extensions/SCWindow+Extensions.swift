//
//  SCWindow+Extensions.swift
//  floating
//
//  Created by Alexandru Turcanu on 11/3/25.
//

import ScreenCaptureKit

// MARK: - Window Extensions

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
