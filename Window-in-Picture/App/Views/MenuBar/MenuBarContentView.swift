//
//  MenuBarContentView.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 11/1/25.
//

import AppKit
import SwiftUI

struct MenuBarContentView: View {
  @Environment(PiPManager.self) private var pipManager
  @Environment(\.dismiss) private var dismiss

  let updaterController: UpdateChecking?
  @State private var isSelectingWindow = false

  init(updaterController: UpdateChecking? = nil) {
    self.updaterController = updaterController
  }

  var body: some View {
    VStack(spacing: 0) {
      MenuBarHeaderView()

      Divider()
        .padding(.horizontal, 9)

      if pipManager.hasPermission {
        menuContent
      } else {
        PermissionPromptView(onEnable: requestPermission)
          .padding()
      }
    }
    .padding(.horizontal, 5)
    .task {
      await refreshOnLaunch()
    }
  }

  private var menuContent: some View {
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

      WindowListView(onSelect: { window in
        pipManager.createPiPWindow(for: window)
        dismiss()
      }, manager: pipManager)
      .frame(maxHeight: 300)

      Divider()
        .padding(.horizontal, 9)

      MenuBarActionsView(
        updaterController: updaterController,
        onQuit: { NSApplication.shared.terminate(nil) },
        manager: pipManager
      )
      .padding(.vertical, 5)
    }
    .frame(width: 320)
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
}

#Preview("Menu Bar Content") {
  MenuBarContentView()
    .environment(PiPManager())
}
