import SwiftUI

struct MenuBarHeaderView: View {
  var body: some View {
    HStack {
      Text("Window-in-Picture")
        .font(.headline)
        .fontWeight(.semibold)
      Spacer()
    }
    .padding(.horizontal, 9)
    .padding(.vertical, 5)
  }
}

#Preview("Menu Bar Header") {
  MenuBarHeaderView()
    .frame(width: 320)
}
