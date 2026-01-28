import AppKit
import ScreenCaptureKit
import SwiftUI

struct AppFiltersView: View {
  @Environment(PiPManager.self) private var pipManager
  @State private var appEntries: [AppEntry] = []
  @State private var excludedBundleIDs = WindowFilterSettings.excludedBundleIDs()
  @State private var loadError: String?

  var body: some View {
    Form {
      Section {
        Text("Exclude apps you don’t want to see in the window list.")
          .foregroundStyle(.secondary)
          .fixedSize(horizontal: false, vertical: true)
      }

      Section {
        if let loadError {
          VStack(alignment: .leading, spacing: 8) {
            Text(loadError)
              .foregroundStyle(.secondary)
            Button("Retry") {
              Task {
                await loadApps()
              }
            }
          }
        } else if appEntries.isEmpty {
          Text("No running apps found.")
            .foregroundStyle(.secondary)
        } else {
          ForEach(appEntries) { entry in
            Toggle(isOn: binding(for: entry.bundleID)) {
              AppRow(entry: entry)
            }
          }
        }
      } footer: {
        Button("Reset to Defaults") {
          resetToDefaults()
        }
      }
    }
    .formStyle(.grouped)
    .task {
      await loadApps()
    }
    .onAppear {
      excludedBundleIDs = WindowFilterSettings.excludedBundleIDs()
    }
    .onChange(of: pipManager.hasPermission) { _, hasPermission in
      guard hasPermission else { return }
      Task {
        await loadApps()
      }
    }
  }

  private func binding(for bundleID: String) -> Binding<Bool> {
    Binding(
      get: { excludedBundleIDs.contains(bundleID) },
      set: { isExcluded in
        if isExcluded {
          excludedBundleIDs.insert(bundleID)
        } else {
          excludedBundleIDs.remove(bundleID)
        }
        WindowFilterSettings.setExcludedBundleIDs(excludedBundleIDs)
        if pipManager.hasPermission {
          Task {
            await pipManager.refreshWindows()
          }
        }
      }
    )
  }

  private func resetToDefaults() {
    WindowFilterSettings.resetToDefaults()
    excludedBundleIDs = WindowFilterSettings.excludedBundleIDs()
    if pipManager.hasPermission {
      Task {
        await pipManager.refreshWindows()
      }
    }
  }

  private func loadApps() async {
    do {
      let content = try await SCShareableContent.excludingDesktopWindows(
        false,
        onScreenWindowsOnly: true
      )
      let apps = content.windows.compactMap { $0.owningApplication }
      var entries: [String: AppEntry] = [:]
      for app in apps {
        let bundleID = app.bundleIdentifier
        guard bundleID.isEmpty == false else { continue }
        if entries[bundleID] == nil {
          entries[bundleID] = AppEntry(
            bundleID: bundleID,
            name: app.applicationName,
            icon: appIcon(for: bundleID)
          )
        }
      }
      appEntries = entries.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
      loadError = nil
    } catch {
      appEntries = []
      loadError = "Allow Screen Recording access to list running apps."
    }
  }

  private func appIcon(for bundleID: String) -> NSImage {
    guard let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) else {
      return NSImage(size: NSSize(width: 24, height: 24))
    }
    let icon = NSWorkspace.shared.icon(forFile: appURL.path)
    icon.size = NSSize(width: 24, height: 24)
    return icon
  }
}

private struct AppEntry: Identifiable {
  let id: String
  let bundleID: String
  let name: String
  let icon: NSImage

  init(bundleID: String, name: String, icon: NSImage) {
    self.id = bundleID
    self.bundleID = bundleID
    self.name = name
    self.icon = icon
  }
}

private struct AppRow: View {
  let entry: AppEntry

  var body: some View {
      Label {
          Text(entry.name)
          Text(entry.bundleID)
      } icon: {
          Image(nsImage: entry.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 20, height: 20)
      }
  }
}

#Preview("Apps") {
  AppFiltersView()
    .environment(PiPManager())
}
