import Foundation

protocol UpdateChecking {
  func checkForUpdates(_ sender: Any?)
}

#if canImport(Sparkle)
import Sparkle

typealias UpdaterController = SPUStandardUpdaterController

@MainActor
extension SPUStandardUpdaterController: UpdateChecking {}

@MainActor
func makeUpdaterController() -> UpdaterController {
  UpdaterController(
    startingUpdater: true,
    updaterDelegate: nil,
    userDriverDelegate: nil
  )
}
#else

@MainActor
final class UpdaterController: UpdateChecking {
  func checkForUpdates(_ sender: Any?) {}
}

@MainActor
func makeUpdaterController() -> UpdaterController {
  UpdaterController()
}
#endif
