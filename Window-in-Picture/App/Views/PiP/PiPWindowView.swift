//
//  PiPWindowView.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import AppKit
import Observation
import SwiftUI

@MainActor
struct PiPWindowView: View {
  @Bindable var manager: PiPManager

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Black background
        Color.black

        if let cgImage = manager.latestFrame {
          let nsImage = NSImage(
            cgImage: cgImage,
            size: NSSize(width: cgImage.width, height: cgImage.height)
          )
          Image(nsImage: nsImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: geometry.size.width, height: geometry.size.height)
        } else {
          // Loading state
          VStack {
            ProgressView()
              .progressViewStyle(CircularProgressViewStyle(tint: .white))
              .scaleEffect(1.5)

            Text("Waiting for stream...")
              .foregroundColor(.white)
              .padding(.top)
          }
        }
      }
    }
  }
}

// Preview
#Preview("PiP Window View") {
  PiPWindowView(manager: PiPManager())
    .frame(width: 400, height: 300)
}
