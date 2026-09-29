import Foundation

enum SimulatorService {
    static func activeSimulators() -> [Simulator] {
        allSimulators()
            .filter { hasContent(at: $0.path) }
            .sorted { lhs, rhs in
                if lhs.isBooted != rhs.isBooted {
                    return lhs.isBooted
                }
                return lhs.lastUsedAt > rhs.lastUsedAt
            }
    }

    static func installedApplications(on simulator: Simulator) -> [Application] {
        let root = simulator.path + "data/Containers/Data/Application/"
        return FileTools.sortedEntries(in: root)
            .compactMap { Application(dataFolderEntry: $0, simulator: simulator) }
            .filter { !$0.isAppleApplication }
    }

    static func appGroups(on simulator: Simulator) -> [AppGroup] {
        let root = simulator.path + "data/Containers/Shared/AppGroup/"
        return FileTools.sortedEntries(in: root)
            .compactMap { AppGroup(entry: $0, simulator: simulator) }
            .filter { !$0.isAppleGroup }
    }

    static func appExtensions(on simulator: Simulator) -> [AppExtension] {
        let root = simulator.path + "data/Containers/Data/PluginKitPlugin/"
        return FileTools.sortedEntries(in: root)
            .compactMap { AppExtension(entry: $0, simulator: simulator) }
            .filter { !$0.isAppleExtension }
    }

    static func realmFiles(inContentPath contentPath: String) -> [RealmFile] {
        var files: [RealmFile] = []
        for sub in AppConfig.RealmConfig.searchSubpaths {
            let folder = contentPath + sub
            for entry in FileTools.sortedEntries(in: folder)
                where (entry.name as NSString).pathExtension == "realm"
            {
                files.append(RealmFile(fileName: entry.name, folder: folder))
            }
        }
        return files
    }

    /// 合并两种发现方式，去重后返回：
    /// 1. 老版 Xcode 会往 `~/Library/Preferences/com.apple.iphonesimulator.plist` 写 `CurrentDeviceUDID`
    ///    和 `DevicePreferences`，只列出用户在 Simulator.app 里用过的机器。
    /// 2. Xcode 26+ 不再维护该 plist，需要直接扫描 `CoreSimulator/Devices/` 目录。
    private static func allSimulators() -> [Simulator] {
        let uuids = simulatorUUIDsFromLegacyPreferences()
            .union(simulatorUUIDsFromDevicesDirectory())
        let devicesDir = devicesRootPath()
        return uuids.compactMap { uuid -> Simulator? in
            let folder = devicesDir + uuid + "/"
            let plist = folder + AppConfig.SimulatorPath.deviceInfoFileName
            return Simulator(devicePlistPath: plist, folder: folder)
        }
    }

    private static func simulatorUUIDsFromLegacyPreferences() -> Set<String> {
        let prefsPath = FileTools.homeDirectory().path + "/" + AppConfig.SimulatorPath.iOSSimulatorPreferences
        guard let properties = NSDictionary(contentsOfFile: prefsPath) else { return [] }

        var uuids = Set<String>()
        if let current = properties["CurrentDeviceUDID"] as? String {
            uuids.insert(current)
        }
        if let devicePreferences = properties["DevicePreferences"] as? [String: Any] {
            uuids.formUnion(devicePreferences.keys)
        }
        return uuids
    }

    private static func simulatorUUIDsFromDevicesDirectory() -> Set<String> {
        let devicesDir = devicesRootPath()
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: devicesDir) else { return [] }
        return Set(entries.filter { !$0.hasPrefix(".") })
    }

    private static func hasContent(at simulatorPath: String) -> Bool {
        let candidates = [
            "data/Containers/Data/Application/",
            "data/Containers/Shared/AppGroup/",
            "data/Containers/Data/PluginKitPlugin/"
        ]
        for sub in candidates {
            let entries = FileTools.contents(of: simulatorPath + sub)
            if entries.contains(where: { $0 != AppConfig.OtherPath.dsStore }) {
                return true
            }
        }
        return false
    }

    private static func devicesRootPath() -> String {
        FileTools.homeDirectory().path + "/" + AppConfig.SimulatorPath.rootRelativePath + "/"
    }
}
