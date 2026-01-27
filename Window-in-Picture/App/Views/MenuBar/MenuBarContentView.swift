//
//  MenuBarContentView.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 11/1/25.
//

import AppKit
import ScreenCaptureKit
import SwiftUI

struct MenuBarContentView: View {
  @Environment(PiPManager.self) private var pipManager
  @Environment(\.dismiss) private var dismiss

  let updaterController: UpdateChecking?
  @State private var isSelectingWindow = false
  private let maxWindowTitleLength = 30

  init(updaterController: UpdateChecking? = nil) {
    self.updaterController = updaterController
  }

  var body: some View {
    Group {
      if pipManager.hasPermission {
        menuContent
      } else {
        permissionMenu
      }
    }
    .task {
      await refreshOnLaunch()
    }
  }

  private var menuContent: some View {
    Group {
      Button {
        selectWindowByClick()
      } label: {
        Label("Select Window", systemImage: "macwindow.badge.plus")
      }
      .disabled(isSelectingWindow)

      Divider()

      windowListSection

      Divider()

      Button {
        Task {
          await pipManager.refreshWindows()
        }
      } label: {
        Label("Refresh", systemImage: "arrow.clockwise")
      }
      .disabled(pipManager.isRefreshing)

      Button {
        updaterController?.checkForUpdates(nil)
      } label: {
        Label("Check for Updates...", systemImage: "square.and.arrow.down")
      }
      .disabled(updaterController == nil)

      Button {
        openAboutWindow()
      } label: {
        Label("About Window-in-Picture", systemImage: "info.circle")
      }

      Divider()

      Button(action: quitApp) {
        Label("Quit", systemImage: "xmark.rectangle")
      }
      .keyboardShortcut("q")
    }
  }

  private var permissionMenu: some View {
    Group {
      Text("Enable Screen Capture Access")
        .fontWeight(.semibold)
        .disabled(true)

      Text("We use Screen Capture to mirror windows for picture-in-picture mode.")
        .disabled(true)

      Divider()

      Button {
        Task {
          await requestPermission()
        }
      } label: {
        Label("Enable", systemImage: "lock.open")
      }
    }
  }

  private var windowListSection: some View {
    Group {
      if pipManager.isRefreshing {
        Text("Loading windows...")
          .disabled(true)
      } else if pipManager.availableWindows.isEmpty {
        Text("No windows available")
          .disabled(true)
      } else {
        ForEach(pipManager.availableWindows, id: \.windowID) { window in
          Button {
            pipManager.createPiPWindow(for: window)
            dismiss()
          } label: {
            Label {
              Text(displayName(for: window))
            } icon: {
              windowIcon(for: window)
            }
          }
        }
      }
    }
  }

  private func refreshOnLaunch() async {
    await pipManager.checkPermission()
    if pipManager.hasPermission {
      await pipManager.refreshWindows()
    }
  }

  private func requestPermission() async {
    await pipManager.requestPermission()
  }

  private func selectWindowByClick() {
    Task {
      isSelectingWindow = true
      defer { isSelectingWindow = false }
      dismiss()

      try? await Task.sleep(nanoseconds: 200_000_000)
      await pipManager.presentWindowPicker()
    }
  }

  private func quitApp() {
    NSApplication.shared.terminate(nil)
  }

  private func openAboutWindow() {
    AboutWindowController.shared.show()
  }

  private func displayName(for window: SCWindow) -> String {
    if let appName = window.owningApplication?.applicationName,
       let windowTitle = window.title {
      return truncatedTitle("\(appName) - \(windowTitle)")
    }
    return truncatedTitle(window.title ?? "Unknown Window")
  }

  private func truncatedTitle(_ title: String) -> String {
    guard title.count > maxWindowTitleLength else { return title }
    let endIndex = title.index(title.startIndex, offsetBy: maxWindowTitleLength)
    return String(title[..<endIndex]).trimmingCharacters(in: .whitespaces) + "…"
  }

  private func windowIcon(for window: SCWindow) -> Image {
    guard let bundleID = window.owningApplication?.bundleIdentifier,
          let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID)
    else {
      return Image(systemName: "app.dashed")
    }

    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
    icon.size = NSSize(width: 16, height: 16)
    return Image(nsImage: icon)
  }
}

#Preview("Menu Bar Content") {
  MenuBarContentView()
    .environment(PiPManager())
}
