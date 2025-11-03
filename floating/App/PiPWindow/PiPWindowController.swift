//
//  PiPWindowController.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import ScreenCaptureKit
import SwiftUI

class PiPWindowController: NSWindowController {
  private var manager: PiPManager
  private var targetWindow: SCWindow

  init(window: SCWindow, manager: PiPManager) {
    self.targetWindow = window
    self.manager = manager

    // Calculate initial window size (quarter of original window)
    let pipWidth = min(window.frame.width / 2, 600)
    let pipHeight = min(window.frame.height / 2, 400)

    // Create the window
    let pipWindow = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: pipWidth, height: pipHeight),
      styleMask: [.titled, .closable, .resizable, .miniaturizable],
      backing: .buffered,
      defer: false
    )

    super.init(window: pipWindow)

    setupWindow()
    setupContent()

    // Start capturing
    Task {
      do {
        try await manager.startCapture(for: window)
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
    window.title = "PiP: \(targetWindow.displayName)"
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

  override func close() {
    // Clean up capture when window closes
    Task { [weak manager] in
      await manager?.stopCapture()
    }
    super.close()
  }
}
