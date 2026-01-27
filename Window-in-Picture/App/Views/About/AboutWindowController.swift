import AppKit
import SwiftUI

@MainActor
final class AboutWindowController: NSWindowController {
  static let shared = AboutWindowController()

  private init() {
    let contentView = AboutView(info: AboutInfo())
    let hostingView = NSHostingView(rootView: contentView)

    let window = NSWindow(
      contentRect: NSRect(x: 0, y: 0, width: 300, height: 520),
      styleMask: [.titled, .closable, .fullSizeContentView],
      backing: .buffered,
      defer: false
    )
    window.title = "About Window-in-Picture"
    window.titleVisibility = .hidden
    window.titlebarAppearsTransparent = true
    window.isMovableByWindowBackground = true
    window.isReleasedWhenClosed = false
    window.backgroundColor = .windowBackgroundColor
    window.isOpaque = true
    window.contentView = hostingView
    window.center()

    super.init(window: window)
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  func show() {
    NSApp.activate(ignoringOtherApps: true)
    window?.makeKeyAndOrderFront(nil)
  }
}

private struct AboutInfo {
  let appName: String
  let version: String
  let build: String
  let commit: String?
  let tagline: String
  let githubURL: URL

  init() {
    let bundle = Bundle.main
    appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? "Window-in-Picture"
    version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    commit = bundle.object(forInfoDictionaryKey: "GitCommit") as? String
    tagline = "Picture-in-picture for any window."
    githubURL = URL(string: "https://github.com/851-labs/Window-in-Picture")!
  }
}

private struct AboutView: View {
  @Environment(\.openURL) private var openURL
  let info: AboutInfo

  var body: some View {
    VStack(alignment: .center) {
      appIcon

      VStack(alignment: .center, spacing: 32) {
        VStack(alignment: .center, spacing: 8) {
          Text(info.appName)
            .bold()
            .font(.title)
          Text(info.tagline)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
            .font(.caption)
            .tint(.secondary)
            .opacity(0.8)
        }
        .textSelection(.enabled)

        VStack(spacing: 2) {
          PropertyRow(label: "Version", text: info.version)
          PropertyRow(label: "Build", text: info.build)
          if let commit = info.commit, commit.isEmpty == false {
            let url = info.githubURL.appendingPathComponent("/commits/\(commit)")
            PropertyRow(label: "Commit", text: commit, url: url)
          }
        }
        .frame(maxWidth: .infinity)

        HStack(spacing: 8) {
          Button("GitHub") {
            openURL(info.githubURL)
          }
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(.top, 8)
    .padding(32)
    .frame(minWidth: 256)
    .background(VisualEffectBackground(material: .underWindowBackground).ignoresSafeArea())
  }

  private var appIcon: some View {
    let icon = NSApp.applicationIconImage
      ?? NSImage(named: NSImage.applicationIconName)
      ?? NSImage(size: NSSize(width: 92, height: 92))
    return Image(nsImage: icon)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(height: 128)
  }
}

private struct VisualEffectBackground: NSViewRepresentable {
  let material: NSVisualEffectView.Material
  let blendingMode: NSVisualEffectView.BlendingMode
  let isEmphasized: Bool

  init(
    material: NSVisualEffectView.Material,
    blendingMode: NSVisualEffectView.BlendingMode = .behindWindow,
    isEmphasized: Bool = false
  ) {
    self.material = material
    self.blendingMode = blendingMode
    self.isEmphasized = isEmphasized
  }

  func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
    nsView.material = material
    nsView.blendingMode = blendingMode
    nsView.isEmphasized = isEmphasized
  }

  func makeNSView(context: Context) -> NSVisualEffectView {
    let visualEffect = NSVisualEffectView()
    visualEffect.autoresizingMask = [.width, .height]
    return visualEffect
  }
}

private struct PropertyRow: View {
  private let label: String
  private let text: String
  private let url: URL?

  init(label: String, text: String, url: URL? = nil) {
    self.label = label
    self.text = text
    self.url = url
  }

  @ViewBuilder private var textView: some View {
    Text(text)
      .frame(width: 120, alignment: .leading)
      .padding(.leading, 2)
      .tint(.secondary)
      .opacity(0.8)
      .monospaced()
  }

  var body: some View {
    HStack(spacing: 4) {
      Text(label)
        .frame(width: 120, alignment: .trailing)
        .padding(.trailing, 2)
      if let url {
        Link(destination: url) {
          textView
        }
      } else {
        textView
      }
    }
    .font(.callout)
    .textSelection(.enabled)
    .frame(maxWidth: .infinity)
  }
}
