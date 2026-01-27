//
//  App.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI

@MainActor
@main
struct WindowInPictureApp: App {
  private let updaterController: UpdateChecking = makeUpdaterController()
  @State private var pipManager = PiPManager()

  var body: some Scene {
    MenuBarExtra {
      MenuBarContentView(updaterController: updaterController)
        .environment(pipManager)
    } label: {
      Image("MenuBarIcon")
        .renderingMode(.template)
    }
    .menuBarExtraStyle(.menu)
  }
}
