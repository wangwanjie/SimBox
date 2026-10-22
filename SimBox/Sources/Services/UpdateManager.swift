import AppKit
import Sparkle

@MainActor
final class UpdateManager: NSObject {
    static let shared = UpdateManager()

    private var controller: SPUStandardUpdaterController!

    override private init() {
        super.init()
        // 需要把 self 作为 delegate 传入，因此先完成 super.init 再创建 controller。
        controller = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: self,
            userDriverDelegate: nil
        )
    }

    var updater: SPUUpdater {
        controller.updater
    }

    func checkForUpdates() {
        controller.checkForUpdates(nil)
    }
}

extension UpdateManager: SPUUpdaterDelegate {
    /// 自 2.2.0 起按架构分别发布 DMG，每种架构读取各自的 appcast。
    nonisolated func feedURLString(for _: SPUUpdater) -> String? {
        let baseFeed = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String
        return UpdateFeed.feedURLString(baseFeedURL: baseFeed, architecture: UpdateFeed.currentArchitecture)
    }
}

/// 纯函数部分，便于单测。
enum UpdateFeed {
    static var currentArchitecture: String {
        #if arch(arm64)
            return "arm64"
        #else
            return "x86_64"
        #endif
    }

    /// `.../appcast.xml` → `.../appcast-arm64.xml`。无法识别时返回 nil，让 Sparkle 使用 Info.plist 默认值。
    static func feedURLString(baseFeedURL: String?, architecture: String) -> String? {
        guard let baseFeedURL, baseFeedURL.hasSuffix(".xml") else {
            return nil
        }
        return String(baseFeedURL.dropLast(".xml".count)) + "-\(architecture).xml"
    }
}
