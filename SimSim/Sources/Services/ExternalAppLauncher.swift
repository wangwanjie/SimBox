import AppKit
import Foundation

enum ExternalAppLauncher {
    static func openInFinder(path: String) {
        NSWorkspace.shared.open(URL(fileURLWithPath: path))
    }

    static func open(path: String, withApplicationAt appPath: String, appendingSubpath: String = "") {
        let full = path + appendingSubpath
        let target = URL(fileURLWithPath: full)
        let appURL = URL(fileURLWithPath: appPath)
        let config = NSWorkspace.OpenConfiguration()
        NSWorkspace.shared.open([target], withApplicationAt: appURL, configuration: config) { _, _ in }
    }

    static func openInTerminal(path: String) {
        open(path: path, withApplicationAt: AppConfig.ExternalApp.terminal)
    }

    static func openInITerm(path: String) {
        open(path: path, withApplicationAt: AppConfig.ExternalApp.iTerm)
    }

    static func openInCommanderOne(path: String) {
        let appPath = FileManager.default.fileExists(atPath: AppConfig.ExternalApp.commanderOnePro)
            ? AppConfig.ExternalApp.commanderOnePro
            : AppConfig.ExternalApp.commanderOne
        // Commander One tends to open the parent — hint it deeper by pointing at Library/.
        open(path: path, withApplicationAt: appPath, appendingSubpath: "Library/")
    }

    static func openInRealmStudio(realmPath: String) {
        let appURL = URL(fileURLWithPath: AppConfig.ExternalApp.realmStudio)
        let target = URL(fileURLWithPath: realmPath)
        NSWorkspace.shared.open([target], withApplicationAt: appURL, configuration: NSWorkspace.OpenConfiguration()) { _, _ in }
    }

    static var isITermAvailable: Bool {
        FileManager.default.fileExists(atPath: AppConfig.ExternalApp.iTerm)
    }

    static var isCommanderOneAvailable: Bool {
        let fm = FileManager.default
        if fm.fileExists(atPath: AppConfig.ExternalApp.commanderOne)
            || fm.fileExists(atPath: AppConfig.ExternalApp.commanderOnePro)
        {
            return true
        }
        let cachedPrefs = NSHomeDirectory() + "/" + AppConfig.OtherPath.commanderOnePreferences
        return fm.fileExists(atPath: cachedPrefs)
    }

    static var isRealmStudioAvailable: Bool {
        FileManager.default.fileExists(atPath: AppConfig.ExternalApp.realmStudio)
    }
}
