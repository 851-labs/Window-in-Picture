//
//  WindowSelector.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI
import AppKit
import ScreenCaptureKit
import Combine

class WindowSelectorOverlay: NSWindow {
    private var eventMonitor: Any?
    private var completion: ((SCWindow?) -> Void)?
    private var availableWindows: [SCWindow] = []
    
    init() {
        super.init(
            contentRect: NSScreen.main?.frame ?? .zero,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        self.isOpaque = false
        self.backgroundColor = NSColor.black.withAlphaComponent(0.3)
        self.level = .screenSaver
        self.ignoresMouseEvents = false
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        
        // Create overlay view
        let overlayView = WindowSelectorView()
        self.contentView = NSHostingView(rootView: overlayView)
    }
    
    func startSelection(windows: [SCWindow], completion: @escaping (SCWindow?) -> Void) {
        self.availableWindows = windows
        self.completion = completion
        
        // Show overlay
        self.makeKeyAndOrderFront(nil)
        
        // Start monitoring mouse events
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            self?.handleMouseEvent(event)
            return nil // Consume the event
        }
        
        // Also monitor for escape key
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 53 { // Escape key
                self?.cancelSelection()
                return nil
            }
            return event
        }
    }
    
    private func handleMouseEvent(_ event: NSEvent) {
        let clickLocation = event.locationInWindow
        let screenLocation = self.convertPoint(toScreen: clickLocation)
        
        // Find window at click location
        if let selectedWindow = findWindow(at: screenLocation) {
            completion?(selectedWindow)
        } else {
            completion?(nil)
        }
        
        endSelection()
    }
    
    private func findWindow(at point: NSPoint) -> SCWindow? {
        // Find the window that contains the clicked point
        return availableWindows.first { window in
            let frame = window.frame
            return frame.contains(point)
        }
    }
    
    private func cancelSelection() {
        completion?(nil)
        endSelection()
    }
    
    private func endSelection() {
        // Clean up
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        self.orderOut(nil)
    }
}

struct WindowSelectorView: View {
    var body: some View {
        ZStack {
            Color.clear
            
            VStack {
                Text("Click on a window to mirror it")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(10)
                
                Text("Press ESC to cancel")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.top, 10)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

// Window selector manager
@MainActor
class WindowSelector: ObservableObject {
    private var overlay: WindowSelectorOverlay?
    
    func selectWindow(from windows: [SCWindow]) async -> SCWindow? {
        await withCheckedContinuation { continuation in
            overlay = WindowSelectorOverlay()
            overlay?.startSelection(windows: windows) { selectedWindow in
                continuation.resume(returning: selectedWindow)
                self.overlay = nil
            }
        }
    }
}
