import Foundation

/// 一台模拟器上需要展示的全部内容。
struct SimulatorContent {
    let simulator: Simulator
    let applications: [Application]
    let appGroups: [AppGroup]
    let appExtensions: [AppExtension]

    var isEmpty: Bool {
        applications.isEmpty && appGroups.isEmpty && appExtensions.isEmpty
    }
}

/// 负责扫描 CoreSimulator 目录。路径可注入，便于单测使用临时目录。
struct SimulatorService {
    /// `~/Library/Developer/CoreSimulator/Devices/`
    let devicesRoot: String
    /// 老版 Xcode 的 `com.apple.iphonesimulator.plist`，不存在时忽略。
    let legacyPreferencesPath: String?

    static let shared: SimulatorService = {
        #if DEBUG
            // 调试 / 截图时可通过环境变量指向一份演示数据，不影响 Release 包。
            if let overrideRoot = ProcessInfo.processInfo.environment["SIMBOX_DEVICES_ROOT"], !overrideRoot.isEmpty {
                return SimulatorService(devicesRoot: overrideRoot)
            }
        #endif
        return SimulatorService(
            devicesRoot: FileTools.homeDirectory().path + "/" + AppConfig.SimulatorPath.rootRelativePath + "/",
            legacyPreferencesPath: FileTools.homeDirectory().path + "/" + AppConfig.SimulatorPath.iOSSimulatorPreferences
        )
    }()

    init(devicesRoot: String, legacyPreferencesPath: String? = nil) {
        self.devicesRoot = devicesRoot.hasSuffix("/") ? devicesRoot : devicesRoot + "/"
        self.legacyPreferencesPath = legacyPreferencesPath
    }

    /// 有容器数据的模拟器：已启动的排最前，其余按最近使用时间倒序。
    func activeSimulators() -> [Simulator] {
        allSimulators()
            .filter { !$0.isDeleted && hasContent(at: $0) }
            .sorted { lhs, rhs in
                if lhs.isBooted != rhs.isBooted {
                    return lhs.isBooted
                }
                if lhs.lastUsedAt != rhs.lastUsedAt {
                    return lhs.lastUsedAt > rhs.lastUsedAt
                }
                return lhs.name < rhs.name
            }
    }

    func content(of simulator: Simulator) -> SimulatorContent {
        SimulatorContent(
            simulator: simulator,
            applications: installedApplications(on: simulator),
            appGroups: appGroups(on: simulator),
            appExtensions: appExtensions(on: simulator)
        )
    }

    func installedApplications(on simulator: Simulator) -> [Application] {
        // 每台模拟器只扫描一次 Bundle 目录，避免每个 app 都全量遍历。
        let bundleIndex = Application.bundleIndex(for: simulator)
        return FileTools.sortedEntries(in: simulator.applicationDataRoot)
            .filter(\.isDirectory)
            .compactMap { Application(dataFolderEntry: $0, simulator: simulator, bundleIndex: bundleIndex) }
            .filter { !$0.isAppleApplication }
    }

    func appGroups(on simulator: Simulator) -> [AppGroup] {
        FileTools.sortedEntries(in: simulator.appGroupRoot)
            .filter(\.isDirectory)
            .compactMap { AppGroup(entry: $0, simulator: simulator) }
            .filter { !$0.isAppleGroup }
    }

    func appExtensions(on simulator: Simulator) -> [AppExtension] {
        FileTools.sortedEntries(in: simulator.appExtensionRoot)
            .filter(\.isDirectory)
            .compactMap { AppExtension(entry: $0, simulator: simulator) }
            .filter { !$0.isAppleExtension }
    }

    static func realmFiles(inContentPath contentPath: String) -> [RealmFile] {
        let base = contentPath.hasSuffix("/") ? contentPath : contentPath + "/"
        var files: [RealmFile] = []
        for sub in AppConfig.RealmConfig.searchSubpaths {
            let folder = base + sub
            for entry in FileTools.sortedEntries(in: folder)
                where (entry.name as NSString).pathExtension == "realm" && !entry.isDirectory {
                files.append(RealmFile(fileName: entry.name, folder: folder))
            }
        }
        return files
    }

    /// 合并两种发现方式，去重后返回：
    /// 1. 老版 Xcode 会往 `~/Library/Preferences/com.apple.iphonesimulator.plist` 写 `CurrentDeviceUDID`
    ///    和 `DevicePreferences`，只列出用户在 Simulator.app 里用过的机器。
    /// 2. Xcode 26+ 不再维护该 plist，需要直接扫描 `CoreSimulator/Devices/` 目录。
    func allSimulators() -> [Simulator] {
        let uuids = simulatorUUIDsFromLegacyPreferences()
            .union(simulatorUUIDsFromDevicesDirectory())
        return uuids.compactMap { uuid -> Simulator? in
            let folder = devicesRoot + uuid + "/"
            let plist = folder + AppConfig.SimulatorPath.deviceInfoFileName
            return Simulator(devicePlistPath: plist, folder: folder)
        }
    }

    private func simulatorUUIDsFromLegacyPreferences() -> Set<String> {
        guard let legacyPreferencesPath, let properties = NSDictionary(contentsOfFile: legacyPreferencesPath) else {
            return []
        }
        var uuids = Set<String>()
        if let current = properties["CurrentDeviceUDID"] as? String {
            uuids.insert(current)
        }
        if let devicePreferences = properties["DevicePreferences"] as? [String: Any] {
            uuids.formUnion(devicePreferences.keys)
        }
        return uuids
    }

    private func simulatorUUIDsFromDevicesDirectory() -> Set<String> {
        guard let entries = try? FileManager.default.contentsOfDirectory(atPath: devicesRoot) else {
            return []
        }
        // Devices 目录下还有 device_set.plist 等文件，只保留有 device.plist 的子目录。
        return Set(entries.filter { name in
            !name.hasPrefix(".")
                && FileManager.default.fileExists(atPath: devicesRoot + name + "/" + AppConfig.SimulatorPath.deviceInfoFileName)
        })
    }

    private func hasContent(at simulator: Simulator) -> Bool {
        [simulator.applicationDataRoot, simulator.appGroupRoot, simulator.appExtensionRoot]
            .contains { FileTools.hasVisibleEntries(in: $0) }
    }
}
