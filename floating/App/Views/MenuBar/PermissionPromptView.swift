import SwiftUI

struct PermissionPromptView: View {
  let onEnable: () async -> Void

  @State private var isRequesting = false

  var body: some View {
    VStack(spacing: 12) {
      Text("Enable Screen Capture Access")
        .font(.headline)
        .fontWeight(.semibold)

      Text("We use Screen Capture to mirror windows for picture-in-picture mode.")
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.bottom, 12)

      Button {
        Task {
          isRequesting = true
          await onEnable()
          isRequesting = false
        }
      } label: {
        Text(isRequesting ? "Enabling..." : "Enable")
      }
      .buttonStyle(.borderedProminent)
      .controlSize(.large)
      .buttonSizing(.flexible)
      .disabled(isRequesting)
    }
  }
}

#Preview("Permission Prompt") {
  PermissionPromptView(onEnable: {})
    .frame(width: 320)
    .padding()
}
