import Foundation

enum AppConfig {
    static let menuIconSize: CGFloat = 16
    static let applicationIconSize: CGFloat = 24
    /// 顶层菜单直接展开的模拟器数量，其余收进 “More Simulators”。
    static let maxRecentSimulators = 5

    static let homepageURL = URL(string: "https://github.com/wangwanjie/SimBox")!
    static let releasesURL = URL(string: "https://github.com/wangwanjie/SimBox/releases")!

    enum MenuTitle {
        static let finder = "Finder"
        static let terminal = "Terminal"
        static let iTerm = "iTerm"
        static let commanderOne = "Commander One"
        static let appBundle = "App bundle in Finder"
        static let userDefaults = "UserDefaults plist"
        static let copyPath = "Copy path"
        static let copyBundleID = "Copy bundle identifier"
        static let resetContainer = "Reset app data…"
        static let deviceFolder = "Device folder in Finder"
        static let copyUDID = "Copy UDID"
        static let moreSimulators = "More Simulators"
        static let noSimulators = "No simulators with installed apps"
        static let startAtLogin = "Launch at login"
        static let checkForUpdates = "Check for updates…"
        static let quit = "Quit SimBox"
    }

    enum SimulatorPath {
        static let deviceInfoFileName = "device.plist"
        static let rootRelativePath = "Library/Developer/CoreSimulator/Devices"
        /// 老版 Xcode（约 Xcode 15 及以前）会在这里维护 CurrentDeviceUDID 和 DevicePreferences，
        /// Xcode 26 起该 plist 通常不再生成。SimulatorService 会同时兼容两种情形。
        static let iOSSimulatorPreferences = "Library/Preferences/com.apple.iphonesimulator.plist"
    }

    enum RealmConfig {
        static let searchSubpaths = ["Documents", "Library/Caches"]
        static let websiteURL = URL(string: "https://github.com/realm/realm-studio")!
    }
}
