//
//  PiPWindowView.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import SwiftUI

struct PiPWindowView: View {
  @Bindable var manager: PiPManager
  @State private var image: NSImage?

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Black background
        Color.black

        if let image = image {
          Image(nsImage: image)
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
    .onChange(of: manager.latestFrame) { _, newValue in
      if let cgImage = newValue {
        self.image = NSImage(
          cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height)
        )
      }
    }
  }
}

// Preview
#Preview("PiP Window View") {
  PiPWindowView(manager: PiPManager())
    .frame(width: 400, height: 300)
}
