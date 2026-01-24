//
//  PiPWindowController.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import AppKit
import ScreenCaptureKit
import SwiftUI

@MainActor
class PiPWindowController: NSWindowController, NSWindowDelegate {
  private let manager: PiPManager
  private let displayName: String

  /// Initialize with an SCWindow (from manual selection in the list)
  convenience init(window: SCWindow, displayName: String, manager: PiPManager) {
    let filter = SCContentFilter(desktopIndependentWindow: window)
    self.init(
      filter: filter,
      displayName: displayName,
      initialSize: NSSize(width: window.frame.width, height: window.frame.height),
      manager: manager
    )
  }

  /// Initialize with an SCContentFilter (from native picker)
  init(filter: SCContentFilter, displayName: String, initialSize: NSSize, manager: PiPManager) {
    self.displayName = displayName
    self.manager = manager

    // Calculate initial window size (quarter of original window)
    let pipWidth = min(initialSize.width / 2, 600)
    let pipHeight = min(initialSize.height / 2, 400)

    // Create the window
    let pipWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: pipWidth, height: pipHeight),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    super.init(window: pipWindow)

    // Set delegate to handle window close
    pipWindow.delegate = self

    setupWindow()
    setupContent()

    // Start capturing
    Task {
      do {
        try await manager.startCapture(with: filter)
      } catch {
        print("Failed to start capture: \(error)")
        self.close()
      }
    }
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  private func setupWindow() {
    guard let window = window else { return }

    // Configure window properties
    window.title = "PiP: \(displayName)"
    window.level = .floating // Always on top
    window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
    window.isMovableByWindowBackground = true
    window.titlebarAppearsTransparent = false
    window.backgroundColor = .black

    // Set minimum size
    window.minSize = NSSize(width: 200, height: 150)

    // Position in bottom-right corner of screen
    if let screen = NSScreen.main {
      let screenFrame = screen.visibleFrame
      let windowFrame = window.frame
      let x = screenFrame.maxX - windowFrame.width - 20
      let y = screenFrame.minY + 20
      window.setFrameOrigin(NSPoint(x: x, y: y))
    }
  }

  private func setupContent() {
    guard let window = window else { return }

    // Create the content view
    let contentView = PiPWindowView(manager: manager)
    let hostingView = NSHostingView(rootView: contentView)

    window.contentView = hostingView
    window.contentView?.wantsLayer = true
  }

  // MARK: - NSWindowDelegate

  func windowWillClose(_ notification: Notification) {
    // Stop capture when window closes
    // Use detached task to ensure it runs even as window controller is being deallocated
    Task {
      await manager.stopCapture()
    }
  }
}
