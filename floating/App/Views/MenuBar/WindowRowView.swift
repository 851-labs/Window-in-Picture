import AppKit
import ScreenCaptureKit
import SwiftUI

struct WindowRowView: View {
  let window: SCWindow
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: 8) {
        if let icon = appIcon {
          Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
        } else {
          Image(systemName: "app.dashed")
            .font(.system(size: 14))
            .frame(width: 20, height: 20)
        }

        VStack(alignment: .leading, spacing: 2) {
          Text(displayName)
            .font(.caption)
            .lineLimit(1)
            .foregroundColor(.primary)

          if let app = window.owningApplication?.applicationName {
            Text(app)
              .font(.caption2)
              .foregroundColor(.secondary)
          }
        }

        Spacer()
      }
      .contentShape(Rectangle())
      .padding(.horizontal, 12)
      .padding(.vertical, 6)
    }
    .buttonStyle(.plain)
    .background(Color.gray.opacity(0.0001))
    .contextMenu {
      #if DEBUG
        Menu("Debug", systemImage: "ant") {
          if let appName = window.owningApplication?.applicationName {
            Section("App") {
              Button(appName, systemImage: "app.grid") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(appName, forType: .string)
              }
            }
          }

          if let bundleID = window.owningApplication?.bundleIdentifier {
            Section("Bundle") {
              Button(bundleID, systemImage: "tag") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(bundleID, forType: .string)
              }
            }
          }

          if let title = window.title {
            Section("Window") {
              Button(title, systemImage: "macwindow") {
                NSPasteboard.general.clearContents()
                NSPasteboard.general.setString(title, forType: .string)
              }
            }
          }

          Divider()

          Button("Copy All Info", systemImage: "doc.on.doc") {
            let appName = window.owningApplication?.applicationName ?? "Unknown"
            let bundleID = window.owningApplication?.bundleIdentifier ?? "No Bundle ID"
            let title = window.title ?? "No Title"
            let info = "App: \(appName)\nBundle ID: \(bundleID)\nWindow: \(title)"
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(info, forType: .string)
          }
        }
      #endif
    }
  }

  private var appIcon: NSImage? {
    guard let bundleID = window.owningApplication?.bundleIdentifier else { return nil }
    let appPath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)?.path
    return NSWorkspace.shared.icon(forFile: appPath ?? "")
  }

  private var displayName: String {
    if let appName = window.owningApplication?.applicationName,
      let windowTitle = window.title
    {
      return "\(appName) - \(windowTitle)"
    }
    return window.title ?? "Unknown Window"
  }
}
