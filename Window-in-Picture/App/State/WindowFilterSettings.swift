import Foundation

enum WindowFilterSettings {
  static let excludedBundleIDsKey = "settings.excludedBundleIDs"

  static let defaultExcludedBundleIDs: [String] = [
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
    "com.steipete.codexbar",
  ]

  static func excludedBundleIDs() -> Set<String> {
    if let stored = UserDefaults.standard.array(forKey: excludedBundleIDsKey) as? [String] {
      return Set(stored)
    }
    return Set(defaultExcludedBundleIDs)
  }

  static func setExcludedBundleIDs(_ bundleIDs: Set<String>) {
    UserDefaults.standard.set(Array(bundleIDs).sorted(), forKey: excludedBundleIDsKey)
  }

  static func resetToDefaults() {
    setExcludedBundleIDs(Set(defaultExcludedBundleIDs))
  }
}
