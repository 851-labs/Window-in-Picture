import Observation
import SwiftUI

struct MenuBarActionsView: View {
  let updaterController: UpdateChecking?
  let onQuit: () -> Void
  @Bindable var manager: PiPManager

  var body: some View {
    VStack(spacing: 0) {
      MenuBarButton(title: "Refresh", icon: "arrow.clockwise") {
        Task {
          await manager.refreshWindows()
        }
      }
      .disabled(manager.isRefreshing)

      MenuBarButton(title: "Check for Updates...", icon: "square.and.arrow.down") {
        updaterController?.checkForUpdates(nil)
      }
      .disabled(updaterController == nil)

      MenuBarButton(title: "Quit", icon: "power") {
        onQuit()
      }
    }
  }
}

#Preview("Menu Bar Actions") {
  MenuBarActionsView(
    updaterController: nil as UpdateChecking?,
    onQuit: {},
    manager: PiPManager()
  )
    .frame(width: 320)
}
