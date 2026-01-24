import Observation
import ScreenCaptureKit
import SwiftUI

struct WindowListView: View {
  let onSelect: (SCWindow) -> Void
  @Bindable var manager: PiPManager

  var body: some View {
    ScrollView {
      VStack(spacing: 2) {
        if manager.isRefreshing {
          loadingState
        } else if manager.availableWindows.isEmpty {
          emptyState
        } else {
          ForEach(manager.availableWindows, id: \.windowID) { window in
            WindowRowView(window: window) {
              onSelect(window)
            }
          }
        }
      }
      .padding(.vertical, 4)
    }
  }

  private var loadingState: some View {
    HStack {
      ProgressView()
        .scaleEffect(0.8)
      Text("Loading windows...")
        .font(.caption)
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 20)
  }

  private var emptyState: some View {
    Text("No windows available")
      .font(.caption)
      .foregroundColor(.secondary)
      .frame(maxWidth: .infinity)
      .padding(.vertical, 20)
  }
}

#Preview("Window List") {
  WindowListView(onSelect: { _ in }, manager: PiPManager())
    .frame(width: 320)
}
