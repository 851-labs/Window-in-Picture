//
//  floatingApp.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI

@main
struct floatingApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowResizability(.contentSize)
        .commands {
            // Remove unnecessary menu items
            CommandGroup(replacing: .newItem) { }
        }
    }
}
