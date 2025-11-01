//
//  CaptureStreamView.swift
//  floating
//
//  Created by Alexandru Turcanu on 10/22/25.
//

import Combine
import SwiftUI

struct CaptureStreamView: View {
  @ObservedObject var streamOutput: CaptureStreamOutput
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
    .onReceive(streamOutput.$latestFrame) { cgImage in
      if let cgImage = cgImage {
        self.image = NSImage(
          cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
      }
    }
  }
}

// Preview
#Preview("Capture Stream View") {
  CaptureStreamView(streamOutput: CaptureStreamOutput())
    .frame(width: 400, height: 300)
}
