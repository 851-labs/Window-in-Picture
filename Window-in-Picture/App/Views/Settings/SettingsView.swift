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
  @State private var loginError: String?

  var body: some View {
    TabView {
      settingsPane
        .tabItem {
          Label("General", systemImage: "gearshape")
        }

      AppFiltersView()
        .tabItem {
          Label("Apps", systemImage: "app.badge")
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
      Section {
        Toggle("Open at Login", isOn: $startAtLoginEnabled)

        if let loginError {
          Text(loginError)
            .font(.caption)
            .foregroundStyle(.red)
        }
      }
    }
    .formStyle(.grouped)
    .padding(12)
    .onAppear {
      startAtLoginEnabled = SMAppService.mainApp.status == .enabled
    }
    .onChange(of: startAtLoginEnabled) { _, newValue in
      loginError = nil
      do {
        if newValue {
          try SMAppService.mainApp.register()
        } else {
          try SMAppService.mainApp.unregister()
        }
      } catch {
        startAtLoginEnabled = SMAppService.mainApp.status == .enabled
        loginError = "Unable to update login item. Please try again."
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
