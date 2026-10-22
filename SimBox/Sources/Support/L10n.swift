import Foundation

/// 所有面向用户的文案。key 使用英文原文，翻译维护在 `Resources/Localizable.xcstrings`（en / zh-Hans / zh-Hant），
/// 界面语言跟随系统。新增文案后需同步补齐 catalog，`LocalizationTests` 会检查缺漏。
enum L10n {
    // MARK: 外部 app 名称（Apple 对 Finder / Terminal 有官方中文名）

    static var finder: String {
        String(localized: "Finder", comment: "Open the folder in Finder")
    }

    static var terminal: String {
        String(localized: "Terminal", comment: "Open the folder in Terminal.app")
    }

    // MARK: 菜单

    static var appBundle: String {
        String(localized: "App bundle in Finder", comment: "Reveal the .app bundle in Finder")
    }

    static var userDefaults: String {
        String(localized: "UserDefaults plist", comment: "Open the app's NSUserDefaults plist file")
    }

    static var copyPath: String {
        String(localized: "Copy path", comment: "Copy the sandbox path to the clipboard")
    }

    static var copyBundleID: String {
        String(localized: "Copy bundle identifier", comment: "Copy the bundle identifier to the clipboard")
    }

    static var resetContainer: String {
        String(localized: "Reset app data…", comment: "Erase the app's sandbox data")
    }

    static var deviceFolder: String {
        String(localized: "Device folder in Finder", comment: "Open the simulator device folder in Finder")
    }

    static var copyUDID: String {
        String(localized: "Copy UDID", comment: "Copy the simulator UDID to the clipboard")
    }

    static var moreSimulators: String {
        String(localized: "More Simulators", comment: "Submenu listing simulators beyond the first five")
    }

    static var noSimulators: String {
        String(localized: "No simulators with installed apps", comment: "Shown when no simulator has user-installed apps")
    }

    static var installRealmStudio: String {
        String(localized: "Install Realm Studio…", comment: "Open the Realm Studio download page")
    }

    static var startAtLogin: String {
        String(localized: "Launch at login", comment: "Toggle launching SimBox at login")
    }

    static var checkForUpdates: String {
        String(localized: "Check for updates…", comment: "Check for a new SimBox version")
    }

    static var quit: String {
        String(localized: "Quit SimBox", comment: "Quit the app")
    }

    static func about(appName: String, version: String) -> String {
        String(localized: "About \(appName) \(version)", comment: "Menu item opening the project homepage; app name and version")
    }

    static var statusItemToolTip: String {
        String(localized: "SimBox — simulator sandbox browser", comment: "Tooltip of the menu bar icon")
    }

    // MARK: 模拟器

    static var booted: String {
        String(localized: "Booted", comment: "Badge for a running simulator")
    }

    static var unknownSimulator: String {
        String(localized: "Unknown Simulator", comment: "Fallback simulator name")
    }

    static var unknownOS: String {
        String(localized: "Unknown OS", comment: "Fallback simulator runtime name")
    }

    // MARK: 弹窗

    static var resetAlertTitle: String {
        String(localized: "Reset app data?", comment: "Reset confirmation title")
    }

    static func resetAlertMessage(target: String) -> String {
        String(
            localized: "All data inside the Documents, Library and tmp folders of \(target) will be erased. This cannot be undone.\nQuit the app on the simulator first, otherwise some data may remain.",
            comment: "Reset confirmation message; app or container name"
        )
    }

    static var reset: String {
        String(localized: "Reset", comment: "Destructive confirm button")
    }

    static var cancel: String {
        String(localized: "Cancel", comment: "Cancel button")
    }

    static var resetFailedTitle: String {
        String(localized: "Some data could not be deleted", comment: "Alert title when resetting partially failed")
    }

    static var loginItemErrorTitle: String {
        String(localized: "Unable to change the launch at login setting", comment: "Alert title when SMAppService fails")
    }
}
