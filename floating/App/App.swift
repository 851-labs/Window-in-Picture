//
//  App.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI

@main
struct floatingApp: App {
  @State private var pipManager = PiPManager()

  var body: some Scene {
    MenuBarExtra("Floating PiP", systemImage: "pip.enter") {
      MenuBarContentView()
        .environment(pipManager)
    }
    .menuBarExtraStyle(.window)
  }
}
