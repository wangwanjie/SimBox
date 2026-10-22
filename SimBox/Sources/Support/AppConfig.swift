import Foundation

enum AppConfig {
    static let menuIconSize: CGFloat = 16
    static let applicationIconSize: CGFloat = 24
    /// 顶层菜单直接展开的模拟器数量，其余收进 “More Simulators”。
    static let maxRecentSimulators = 5

    static let homepageURL = URL(string: "https://github.com/wangwanjie/SimBox")!
    static let releasesURL = URL(string: "https://github.com/wangwanjie/SimBox/releases")!

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
