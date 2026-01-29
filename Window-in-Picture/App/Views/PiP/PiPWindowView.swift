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
  let onClose: () -> Void
  @State private var isHovering = false

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .topLeading) {
        // Black background
        Color.black

        if let cgImage = manager.latestFrame {
          Image(decorative: cgImage, scale: 1.0, orientation: .up)
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

        Color.black
          .opacity(isHovering ? 0.3 : 0)
          .animation(.easeInOut(duration: 0.15), value: isHovering)
          .allowsHitTesting(false)

        closeButton
          .padding(10)
          .opacity(isHovering ? 1 : 0)
          .scaleEffect(isHovering ? 1.0 : 0.95)
          .animation(.easeInOut(duration: 0.15), value: isHovering)
          .allowsHitTesting(isHovering)
      }
      .ignoresSafeArea()
      .onHover { hovering in
        isHovering = hovering
      }
    }
  }
}

private extension PiPWindowView {
  @ViewBuilder
  var closeButton: some View {
    Button(action: onClose) {
      Image(systemName: "xmark")
        .font(.system(size: 15, weight: .semibold))
        .frame(width: 36, height: 36)
    }
    .buttonStyle(.plain)
    .foregroundStyle(.white)
    .glassEffect(.regular.interactive(), in: .circle)
  }
}

// Preview
#Preview("PiP Window View") {
  PiPWindowView(manager: PiPManager(), onClose: {})
    .frame(width: 400, height: 300)
}
