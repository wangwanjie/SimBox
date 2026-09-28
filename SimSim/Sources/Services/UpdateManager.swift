import AppKit
import Sparkle

@MainActor
final class UpdateManager: NSObject {
    static let shared = UpdateManager()

    private let controller: SPUStandardUpdaterController

    override private init() {
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        super.init()
    }

    var updater: SPUUpdater {
        controller.updater
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}
