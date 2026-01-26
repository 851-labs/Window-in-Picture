//
//  MenuBarButton.swift
//  Window-in-Picture
//
//  Created by Alexandru Turcanu on 12/3/25.
//

import SwiftUI

struct MenuBarButton: View {
  let title: String
  var icon: String? = nil
  let action: () -> Void

  @State private var isHovering = false

  var body: some View {
    Button {
      action()
    } label: {
      HStack(spacing: 8) {
        if let icon = icon {
          Image(systemName: icon)
            .foregroundStyle(.secondary)
        }
        Text(title)
          .foregroundStyle(.primary)
        Spacer()
      }
      .frame(height: 22)
      .padding(.horizontal, 10)
      .background(
        RoundedRectangle(cornerRadius: 10)
          .fill(isHovering
            ? Color(nsColor: .secondarySystemFill)
            : Color.clear
          )
      )
    }
    .buttonStyle(.plain)
    .onHover { hovering in
      isHovering = hovering
    }
  }
}

// MARK: - Preview

#Preview("MenuBarButton") {
  VStack(spacing: 0) {
    VStack(spacing: 0) {
      MenuBarButton(title: "Select Window", icon: "macwindow.badge.plus") {}
      MenuBarButton(title: "Refresh", icon: "arrow.clockwise") {}
      MenuBarButton(title: "Close All", icon: "xmark.rectangle") {}
      MenuBarButton(title: "Quit", icon: "power") {}
    }
    .padding(.vertical, 5)

    Divider()

    VStack(spacing: 0) {
      MenuBarButton(title: "No Icon") {}
    }
    .padding(.vertical, 5)
  }
  .frame(width: 320)
  .padding(.horizontal, 5)
}
