import AppKit
import Foundation

/// 可选的第三方/系统 app。先按 bundle ID 让 LaunchServices 查找（覆盖 ~/Applications、
/// 自定义安装位置），找不到再回退到常见安装路径。
struct ExternalApp {
    let name: String
    let bundleIdentifiers: [String]
    let candidatePaths: [String]

    static let finder = ExternalApp(
        name: AppConfig.MenuTitle.finder,
        bundleIdentifiers: ["com.apple.finder"],
        candidatePaths: ["/System/Library/CoreServices/Finder.app"]
    )
    static let terminal = ExternalApp(
        name: AppConfig.MenuTitle.terminal,
        bundleIdentifiers: ["com.apple.Terminal"],
        candidatePaths: ["/System/Applications/Utilities/Terminal.app", "/Applications/Utilities/Terminal.app"]
    )
    static let iTerm = ExternalApp(
        name: AppConfig.MenuTitle.iTerm,
        bundleIdentifiers: ["com.googlecode.iterm2"],
        candidatePaths: applicationPaths("iTerm.app")
    )
    static let commanderOne = ExternalApp(
        name: AppConfig.MenuTitle.commanderOne,
        bundleIdentifiers: ["com.eltima.cmd1", "com.eltima.cmd1pro"],
        candidatePaths: applicationPaths("Commander One PRO.app") + applicationPaths("Commander One.app")
    )
    static let realmStudio = ExternalApp(
        name: "Realm Studio",
        bundleIdentifiers: ["io.realm.realm-studio", "io.realm.realmstudio"],
        candidatePaths: applicationPaths("Realm Studio.app")
    )

    /// `/Applications/X.app` 与 `~/Applications/X.app`。
    static func applicationPaths(_ bundleName: String) -> [String] {
        ["/Applications/\(bundleName)", NSHomeDirectory() + "/Applications/\(bundleName)"]
    }

    var url: URL? {
        for identifier in bundleIdentifiers {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: identifier) {
                return url
            }
        }
        let fm = FileManager.default
        return candidatePaths.first { fm.fileExists(atPath: $0) }.map { URL(fileURLWithPath: $0) }
    }

    var isAvailable: Bool {
        url != nil
    }

    func icon(size: CGFloat) -> NSImage? {
        guard let url else {
            return nil
        }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        icon.size = NSSize(width: size, height: size)
        return icon
    }
}

enum ExternalAppLauncher {
    static func openInFinder(path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    /// 在 Finder 中选中文件（而不是打开它）。
    static func revealInFinder(path: String) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
    }

    static func open(path: String, with app: ExternalApp) {
        guard let appURL = app.url else {
            NSLog("[SimBox] \(app.name) is not installed")
            NSSound.beep()
            return
        }
        let target = URL(fileURLWithPath: path)
        let config = NSWorkspace.OpenConfiguration()
        config.activates = true
        NSWorkspace.shared.open([target], withApplicationAt: appURL, configuration: config) { _, error in
            if let error {
                NSLog("[SimBox] Failed to open \(path) with \(app.name): \(error.localizedDescription)")
            }
        }
    }

    static func openInTerminal(path: String) {
        open(path: path, with: .terminal)
    }

    static func openInITerm(path: String) {
        open(path: path, with: .iTerm)
    }

    static func openInCommanderOne(path: String) {
        // Commander One 打开目录时会停在父级，直接指向 Library/ 让它进到容器内部。
        let library = (path.hasSuffix("/") ? path : path + "/") + "Library/"
        let target = FileManager.default.fileExists(atPath: library) ? library : path
        open(path: target, with: .commanderOne)
    }

    static func openInRealmStudio(realmPath: String) {
        open(path: realmPath, with: .realmStudio)
    }

    /// 用系统默认 app 打开文件（如 plist 用 Xcode 打开）。
    static func openWithDefaultApp(path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }
}
