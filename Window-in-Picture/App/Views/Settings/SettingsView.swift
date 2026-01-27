//
//  SettingsView.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 1/27/26.
//

import ServiceManagement
import SwiftUI

struct SettingsView: View {
  let updaterController: UpdateChecking
  @State private var startAtLoginEnabled = SMAppService.mainApp.status == .enabled

  var body: some View {
    TabView {
      settingsPane
        .tabItem {
          Label("General", systemImage: "gearshape")
        }

      AboutView(info: AboutInfo(), updaterController: updaterController)
        .tabItem {
          Label("About", systemImage: "info.circle")
        }
    }
    .frame(maxWidth: 520)
    .frame(minWidth: 420, minHeight: 360)
  }

  private var settingsPane: some View {
    Form {
      Section("Login") {
        Toggle("Open at Login", isOn: $startAtLoginEnabled)
      }
    }
    .formStyle(.grouped)
    .padding(12)
    .onAppear {
      startAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }
    .onChange(of: startAtLoginEnabled) { _, newValue in
      do {
        if newValue {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
      } catch {
        startAtLoginEnabled = SMAppService.mainApp.status == .enabled
      }
    }
  }
}

#Preview("Settings") {
  SettingsView(updaterController: PreviewUpdaterController())
}

private final class PreviewUpdaterController: UpdateChecking {
  func checkForUpdates(_ sender: Any?) {}
}
