//
//  WindowPickerView.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI
import ScreenCaptureKit

struct WindowPickerView: View {
    @StateObject private var captureManager = WindowCaptureManager()
    @StateObject private var pipManager = PiPWindowManager()
    @StateObject private var windowSelector = WindowSelector()
    @State private var isSelectingWindow = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            VStack(spacing: 10) {
                Image(systemName: "pip.enter")
                    .font(.system(size: 60))
                    .foregroundStyle(.tint)
                
                Text("Floating PiP")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Mirror any window in picture-in-picture mode")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
            
            Divider()
            
            if !captureManager.hasPermission {
                // Permission request view
                VStack(spacing: 15) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.yellow)
                    
                    Text("Screen Recording Permission Required")
                        .font(.headline)
                    
                    Text("This app needs screen recording permission to mirror windows.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    
                    Button(action: {
                        Task {
                            await captureManager.requestPermission()
                        }
                    }) {
                        Label("Grant Permission", systemImage: "checkmark.circle")
                            .frame(minWidth: 200)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            } else {
                // Main interface
                VStack(spacing: 15) {
                    // Quick select button
                    Button(action: selectWindowByClick) {
                        HStack {
                            Image(systemName: "cursorarrow.click")
                            Text("Click to Select Window")
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    .disabled(isSelectingWindow)
                    
                    // Window list
                    ScrollView {
                        VStack(spacing: 10) {
                            if captureManager.isRefreshing {
                                ProgressView("Loading windows...")
                                    .frame(maxWidth: .infinity, minHeight: 100)
                            } else if captureManager.availableWindows.isEmpty {
                                Text("No windows available")
                                    .foregroundColor(.secondary)
                                    .frame(maxWidth: .infinity, minHeight: 100)
                            } else {
                                ForEach(captureManager.availableWindows, id: \.windowID) { window in
                                    WindowRow(window: window) {
                                        pipManager.createPiPWindow(for: window, captureManager: captureManager)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .frame(maxHeight: 400)
                    
                    // Refresh button
                    HStack {
                        Button(action: {
                            Task {
                                await captureManager.refreshWindows()
                            }
                        }) {
                            Label("Refresh", systemImage: "arrow.clockwise")
                        }
                        .disabled(captureManager.isRefreshing)
                        
                        Spacer()
                        
                        Button(action: {
                            pipManager.closeAllWindows()
                        }) {
                            Label("Close All PiP", systemImage: "xmark.circle")
                        }
                        .buttonStyle(.borderless)
                    }
                    .padding(.horizontal)
                }
            }
            
            Spacer()
        }
        .frame(width: 500, height: 600)
        .padding()
    }
    
    private func selectWindowByClick() {
        Task {
            isSelectingWindow = true
            if let selectedWindow = await windowSelector.selectWindow(from: captureManager.availableWindows) {
                pipManager.createPiPWindow(for: selectedWindow, captureManager: captureManager)
            }
            isSelectingWindow = false
        }
    }
}

struct WindowRow: View {
    let window: SCWindow
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // App icon
                if let icon = window.appIcon {
                    Image(nsImage: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "app.dashed")
                        .font(.system(size: 24))
                        .frame(width: 32, height: 32)
                }
                
                // Window info
                VStack(alignment: .leading, spacing: 4) {
                    Text(window.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if let app = window.owningApplication?.applicationName {
                        Text(app)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // PiP icon
                Image(systemName: "pip.enter")
                    .font(.title3)
                    .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

struct WindowPickerView_Previews: PreviewProvider {
    static var previews: some View {
        WindowPickerView()
    }
}

