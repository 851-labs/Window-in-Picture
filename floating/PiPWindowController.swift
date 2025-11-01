//
//  PiPWindowController.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI
import AppKit
import ScreenCaptureKit
import Combine

class PiPWindowController: NSWindowController {
    private var streamOutput: CaptureStreamOutput
    private var captureManager: WindowCaptureManager
    private var targetWindow: SCWindow
    
    init(window: SCWindow, captureManager: WindowCaptureManager) {
        self.targetWindow = window
        self.captureManager = captureManager
        self.streamOutput = CaptureStreamOutput()
        
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
                try await captureManager.startCapture(for: window, streamOutput: streamOutput)
            } catch {
                print("Failed to start capture: \(error)")
                self.close()
            }
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupWindow() {
        guard let window = self.window else { return }
        
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
        guard let window = self.window else { return }
        
        // Create the content view
        let contentView = CaptureStreamView(streamOutput: streamOutput)
        let hostingView = NSHostingView(rootView: contentView)
        
        window.contentView = hostingView
        window.contentView?.wantsLayer = true
    }
    
    override func close() {
        // Clean up capture when window closes
        Task {
            await captureManager.stopCapture()
        }
        super.close()
    }
}

// Manager for all PiP windows
@MainActor
class PiPWindowManager: ObservableObject {
    private var windowControllers: [PiPWindowController] = []
    
    func createPiPWindow(for window: SCWindow, captureManager: WindowCaptureManager) {
        // Check if we already have a PiP window for this source
        let existingController = windowControllers.first { controller in
            controller.window?.title.contains(window.displayName) ?? false
        }
        
        if let existingController = existingController {
            // Bring existing window to front
            existingController.window?.makeKeyAndOrderFront(nil)
            return
        }
        
        // Create new PiP window
        let controller = PiPWindowController(window: window, captureManager: captureManager)
        windowControllers.append(controller)
        
        // Show the window
        controller.showWindow(nil)
        
        // Remove controller when window closes
        NotificationCenter.default.addObserver(
            forName: NSWindow.willCloseNotification,
            object: controller.window,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.windowControllers.removeAll { $0 === controller }
            }
        }
    }
    
    func closeAllWindows() {
        windowControllers.forEach { $0.close() }
        windowControllers.removeAll()
    }
}
