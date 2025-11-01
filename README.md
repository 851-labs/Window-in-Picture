# Floating PiP - Picture-in-Picture Window Mirror for macOS

A macOS app that allows you to mirror any window in a floating picture-in-picture mode, perfect for keeping an eye on Terminal, Slack, or any other app while working.

## Features

- **Click-to-Select**: Simply click on any window to create a PiP mirror
- **Window List**: Browse and select from a list of all open windows
- **Real-time Mirroring**: 30 FPS live updates of the selected window
- **Floating Windows**: PiP windows stay on top of all other windows
- **Resizable**: Adjust PiP window size to your preference
- **Multiple Windows**: Create multiple PiP windows simultaneously

## Requirements

- macOS 15.0 or later
- Screen recording permission (requested on first launch)

## How to Use

1. **Build and Run**: Open the project in Xcode and press Cmd+R to build and run
2. **Grant Permission**: When prompted, grant screen recording permission in System Settings
3. **Select a Window**:
   - Click "Click to Select Window" and then click on any window you want to mirror
   - OR browse the window list and click on a window entry
4. **Manage PiP Windows**:
   - Resize by dragging window corners
   - Move by dragging the title bar
   - Close individual PiP windows with the close button
   - Use "Close All PiP" to close all floating windows at once

## Technical Details

- Built with SwiftUI and ScreenCaptureKit
- Uses modern macOS 15 APIs for efficient screen capture
- Implements proper memory management for streaming
- Supports multiple displays

## Privacy & Security

This app requires screen recording permission to function. It only captures windows you explicitly select and does not store or transmit any captured content. All processing happens locally on your device.

