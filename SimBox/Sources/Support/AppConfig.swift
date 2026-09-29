import Foundation

enum AppConfig {
    static let menuIconSize: CGFloat = 16
    static let applicationIconSize: CGFloat = 24
    static let maxRecentSimulators = 5

    static let homepageURL = URL(string: "https://github.com/wangwanjie/SimBox")!

    enum ExternalApp {
        static let finder = "/System/Library/CoreServices/Finder.app"
        static let terminal = "/System/Applications/Utilities/Terminal.app"
        static let iTerm = "/Applications/iTerm.app"
        static let commanderOne = "/Applications/Commander One.app"
        static let commanderOnePro = "/Applications/Commander One PRO.app"
        static let realmStudio = "/Applications/Realm Studio.app"

        static let iTermBundleID = "com.googlecode.iterm2"
    }

    enum MenuTitle {
        static let finder = "Finder"
        static let terminal = "Terminal"
        static let iTerm = "iTerm"
        static let commanderOne = "Commander One"
        static let copyPath = "Copy path"
        static let resetContainer = "Reset app data"
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

    enum OtherPath {
        static let commanderOnePreferences = "Library/Preferences/com.eltima.cmd1.plist"
        static let dsStore = ".DS_Store"
    }
}
