import Foundation
@testable import SimBox

/// 在临时目录中搭建与 `CoreSimulator/Devices` 相同结构的假数据。
final class SimulatorFixture {
    let root: URL
    let devicesRoot: URL
    private let fm = FileManager.default

    init() throws {
        root = fm.temporaryDirectory.appendingPathComponent("SimBoxTests-\(UUID().uuidString)", isDirectory: true)
        devicesRoot = root.appendingPathComponent("Devices", isDirectory: true)
        try fm.createDirectory(at: devicesRoot, withIntermediateDirectories: true)
    }

    deinit {
        try? FileManager.default.removeItem(at: root)
    }

    var service: SimulatorService {
        SimulatorService(devicesRoot: devicesRoot.path, legacyPreferencesPath: root.appendingPathComponent("legacy.plist").path)
    }

    @discardableResult
    func addDevice(
        udid: String = UUID().uuidString,
        name: String = "iPhone 18",
        runtime: String = "com.apple.CoreSimulator.SimRuntime.iOS-27-0",
        state: Int = 1,
        lastUsedAt: Date? = nil,
        isDeleted: Bool = false
    ) throws
        -> URL {
        let folder = devicesRoot.appendingPathComponent(udid, isDirectory: true)
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        var plist: [String: Any] = [
            "UDID": udid,
            "name": name,
            "runtime": runtime,
            "state": state,
            "isDeleted": isDeleted
        ]
        if let lastUsedAt {
            plist["lastUsedAt"] = lastUsedAt
        }
        try writePlist(plist, to: folder.appendingPathComponent("device.plist"))
        return folder
    }

    /// 安装一个 app：Bundle 容器 + Data 容器，返回 Data 容器路径。
    @discardableResult
    func installApp(
        on device: URL,
        bundleID: String,
        infoPlist: [String: Any] = [:],
        iconFiles: [String] = [],
        modificationDate: Date? = nil
    ) throws
        -> URL {
        let containers = device.appendingPathComponent("data/Containers", isDirectory: true)
        let bundleContainer = containers.appendingPathComponent("Bundle/Application/\(UUID().uuidString)", isDirectory: true)
        let appFolder = bundleContainer.appendingPathComponent("App.app", isDirectory: true)
        try fm.createDirectory(at: appFolder, withIntermediateDirectories: true)
        try writeMetadata(identifier: bundleID, in: bundleContainer)
        try writePlist(infoPlist, to: appFolder.appendingPathComponent("Info.plist"))
        for icon in iconFiles {
            try Data().write(to: appFolder.appendingPathComponent(icon))
        }

        let dataContainer = containers.appendingPathComponent("Data/Application/\(UUID().uuidString)", isDirectory: true)
        for sub in ["Documents", "Library/Caches", "Library/Preferences", "tmp", "SystemData"] {
            try fm.createDirectory(at: dataContainer.appendingPathComponent(sub), withIntermediateDirectories: true)
        }
        try writeMetadata(identifier: bundleID, in: dataContainer)
        if let modificationDate {
            try fm.setAttributes([.modificationDate: modificationDate], ofItemAtPath: dataContainer.path)
        }
        return dataContainer
    }

    @discardableResult
    func addSharedContainer(on device: URL, kind: String, identifier: String) throws -> URL {
        let container = device.appendingPathComponent("data/Containers/\(kind)/\(UUID().uuidString)", isDirectory: true)
        try fm.createDirectory(at: container.appendingPathComponent("Library"), withIntermediateDirectories: true)
        try writeMetadata(identifier: identifier, in: container)
        return container
    }

    func writeLegacyPreferences(_ plist: [String: Any]) throws {
        try writePlist(plist, to: root.appendingPathComponent("legacy.plist"))
    }

    func writeMetadata(identifier: String, in container: URL) throws {
        try writePlist(["MCMMetadataIdentifier": identifier], to: container.appendingPathComponent(ContainerMetadata.fileName))
    }

    func writePlist(_ plist: [String: Any], to url: URL) throws {
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: url)
    }
}
