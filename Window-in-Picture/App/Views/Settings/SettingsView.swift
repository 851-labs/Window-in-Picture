//
//  SettingsView.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 1/27/26.
//

import SwiftUI

struct SettingsView: View {
  @AppStorage("settings.autoRefreshOnLaunch") private var autoRefreshOnLaunch = true
  @AppStorage("settings.showWindowTitles") private var showWindowTitles = true

  var body: some View {
    Form {
      Section("Window List") {
        Toggle("Auto-refresh on launch", isOn: $autoRefreshOnLaunch)
        Toggle("Show window titles", isOn: $showWindowTitles)
      }

      Section("About") {
        Text("Settings are in progress. More options coming soon.")
          .foregroundStyle(.secondary)
      }
    }
    .frame(minWidth: 360)
    .padding(12)
  }
}

#Preview("Settings") {
  SettingsView()
}
