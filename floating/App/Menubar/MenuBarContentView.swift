//
//  MenuBarContentView.swift
//  floating
//
//  Created by Alexandru Turcanu on 11/1/25.
//

import AppKit
import ScreenCaptureKit
import SwiftUI

struct MenuBarContentView: View {
  @Environment(PiPManager.self) private var pipManager
  @Environment(\.dismiss) private var dismiss

  @State private var isSelectingWindow = false

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        Text("Window in Picture")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 9)
      .padding(.vertical, 5)

      Divider()
        .padding(.horizontal, 9)

      if !pipManager.hasPermission {
        VStack(spacing: 12) {
          Text("Enable Screen Capture Access")
            .font(.headline)
            .fontWeight(.semibold)
          Text("We use Screen Capture to mirror windows for picture-in-picture mode.")
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.bottom, 12)

          Button {
            Task {
              await pipManager.requestPermission()
            }
          } label: {
            Text("Enable")
          }
          .buttonStyle(.borderedProminent)
          .controlSize(.large)
          .buttonSizing(.flexible)
        }
        .padding()
      } else {
        VStack(spacing: 0) {
          VStack(spacing: 0) {
            MenuBarButton(title: "Select Window", icon: "macwindow.badge.plus") {
              selectWindowByClick()
            }
            .disabled(isSelectingWindow)
          }
          .padding(.vertical, 5)

          Divider()
            .padding(.horizontal, 9)

          ScrollView {
            VStack(spacing: 2) {
              if pipManager.isRefreshing {
                HStack {
                  ProgressView()
                    .scaleEffect(0.8)
                  Text("Loading windows...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
              } else if pipManager.availableWindows.isEmpty {
                Text("No windows available")
                  .font(.caption)
                  .foregroundColor(.secondary)
                  .frame(maxWidth: .infinity)
                  .padding(.vertical, 20)
              } else {
                ForEach(pipManager.availableWindows, id: \.windowID) { window in
                  MenuBarWindowRow(window: window) {
                    pipManager.createPiPWindow(for: window)
                    dismiss()
                  }
                }
              }
            }
            .padding(.vertical, 4)
          }
          .frame(maxHeight: 300)

          Divider()
            .padding(.horizontal, 9)

          VStack(spacing: 0) {
            MenuBarButton(title: "Refresh", icon: "arrow.clockwise") {
              Task {
                await pipManager.refreshWindows()
              }
            }
            .disabled(pipManager.isRefreshing)

            MenuBarButton(title: "Quit", icon: "power") {
              NSApplication.shared.terminate(nil)
            }
          }
          .padding(.vertical, 5)
        }
        .frame(width: 320)
      }
    }
    .padding(.horizontal, 5)
    .task {
      await pipManager.checkPermission()
      if pipManager.hasPermission {
        await pipManager.refreshWindows()
      }
    }
  }

  private func selectWindowByClick() {
    Task {
      isSelectingWindow = true
      dismiss()

      // Small delay to allow popover to close
      try? await Task.sleep(nanoseconds: 200_000_000)

      await pipManager.presentWindowPicker()
      isSelectingWindow = false
    }
  }
}

// MARK: - Menu Bar Window Row

struct MenuBarWindowRow: View {
  let window: SCWindow
  let action: () -> Void

  var body: some View {
    Button {
      action()
    } label: {
      HStack(spacing: 8) {
        // App icon
        if let icon = window.appIcon {
          Image(nsImage: icon)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 20, height: 20)
        } else {
          Image(systemName: "app.dashed")
            .font(.system(size: 14))
            .frame(width: 20, height: 20)
        }

        // Window info
        VStack(alignment: .leading, spacing: 2) {
          Text(window.displayName)
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
}

// MARK: - Preview

#Preview("Menu Bar Content") {
  MenuBarContentView()
    .environment(PiPManager())
}
