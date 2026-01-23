//
//  App.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import Sparkle
import SwiftUI

@main
struct WindowInPictureApp: App {
  private let updaterController = SPUStandardUpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
  )
  @State private var pipManager = PiPManager()

  var body: some Scene {
    MenuBarExtra("Window-in-Picture", systemImage: "pip.enter") {
      MenuBarContentView(updaterController: updaterController)
        .environment(pipManager)
    }
    .menuBarExtraStyle(.window)
  }
}
