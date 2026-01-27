import AppKit
import SwiftUI

struct AboutView: View {
  @Environment(\.openURL) private var openURL
  let info: AboutInfo
  let updaterController: UpdateChecking

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
        }
        .frame(maxWidth: .infinity)

        HStack(spacing: 8) {
          Button("Check for Updates") {
            updaterController.checkForUpdates(nil as Any?)
          }

          Button("GitHub") {
            openURL(info.githubURL)
          }
        }
      }
      .frame(maxWidth: .infinity)
    }
    .padding(.top, 8)
    .padding(32)
    .padding(.bottom, 12)
    .frame(minWidth: 256)
    .frame(maxHeight: .infinity)
  }

  private var appIcon: some View {
    let icon = NSImage(named: "AppIcon") ?? NSImage(size: NSSize(width: 92, height: 92))
    return Image(nsImage: icon)
      .resizable()
      .aspectRatio(contentMode: .fit)
      .frame(height: 128)
  }
}

struct AboutInfo {
  let appName: String
  let version: String
  let build: String
  let tagline: String
  let githubURL: URL

  init() {
    let bundle = Bundle.main
    appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
      ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
      ?? "Window-in-Picture"
    version = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    build = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    tagline = "Picture-in-picture for any window."
    githubURL = URL(string: "https://github.com/851-labs/Window-in-Picture")!
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

#Preview("About") {
  AboutView(info: AboutInfo(), updaterController: PreviewUpdaterController())
}

private final class PreviewUpdaterController: UpdateChecking {
  func checkForUpdates(_ sender: Any?) {}
}
