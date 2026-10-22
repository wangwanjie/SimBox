@testable import SimBox
import XCTest

final class SimulatorServiceTests: XCTestCase {
    private var fixture: SimulatorFixture!

    override func setUpWithError() throws {
        fixture = try SimulatorFixture()
    }

    override func tearDown() {
        fixture = nil
    }

    func testActiveSimulatorsOrderingAndFiltering() throws {
        let old = try fixture.addDevice(udid: "OLD", name: "Old", lastUsedAt: Date(timeIntervalSince1970: 100))
        let recent = try fixture.addDevice(udid: "RECENT", name: "Recent", lastUsedAt: Date(timeIntervalSince1970: 200))
        let booted = try fixture.addDevice(udid: "BOOTED", name: "Booted", state: 3, lastUsedAt: Date(timeIntervalSince1970: 50))
        let deleted = try fixture.addDevice(udid: "DELETED", isDeleted: true)
        try fixture.addDevice(udid: "EMPTY")
        for device in [old, recent, booted, deleted] {
            try fixture.installApp(on: device, bundleID: "com.example.app")
        }
        // Devices 目录下的普通文件不应被当成设备。
        try Data().write(to: fixture.devicesRoot.appendingPathComponent("device_set.plist"))

        let udids = fixture.service.activeSimulators().map(\.udid)
        XCTAssertEqual(udids, ["BOOTED", "RECENT", "OLD"])
    }

    func testLegacyPreferencesAreMergedWithoutDuplicates() throws {
        let device = try fixture.addDevice(udid: "LEGACY")
        try fixture.installApp(on: device, bundleID: "com.example.app")
        try fixture.writeLegacyPreferences([
            "CurrentDeviceUDID": "LEGACY",
            "DevicePreferences": ["LEGACY": [:], "MISSING": [:]]
        ])
        XCTAssertEqual(fixture.service.allSimulators().map(\.udid), ["LEGACY"])
    }

    func testInstalledApplicationsResolveBundleInfo() throws {
        let device = try fixture.addDevice()
        try fixture.installApp(
            on: device,
            bundleID: "com.example.demo",
            infoPlist: [
                "CFBundleDisplayName": "Demo",
                "CFBundleShortVersionString": "2.0",
                "CFBundleVersion": "9"
            ],
            modificationDate: Date(timeIntervalSince1970: 100)
        )
        try fixture.installApp(on: device, bundleID: "com.example.newer", modificationDate: Date(timeIntervalSince1970: 200))
        try fixture.installApp(on: device, bundleID: "com.apple.mobilesafari")

        let simulator = try XCTUnwrap(fixture.service.activeSimulators().first)
        let apps = fixture.service.installedApplications(on: simulator)

        // 系统 app 被过滤，最近修改的排在前面。
        XCTAssertEqual(apps.map(\.bundleIdentifier), ["com.example.newer", "com.example.demo"])
        let demo = apps[1]
        XCTAssertEqual(demo.displayTitle, "Demo 2.0 (9)")
        XCTAssertNotNil(demo.bundlePath)
        XCTAssertTrue(demo.bundlePath?.hasSuffix("App.app/") ?? false)
        XCTAssertTrue(demo.contentPath.hasSuffix("/"))
        XCTAssertEqual(demo.preferencesPlistPath, demo.contentPath + "Library/Preferences/com.example.demo.plist")
        // 没有 Info.plist 名称时回退到 bundle ID。
        XCTAssertEqual(apps[0].displayTitle, "com.example.newer")
    }

    func testDataContainerWithoutMetadataIsSkipped() throws {
        let device = try fixture.addDevice()
        let container = try fixture.installApp(on: device, bundleID: "com.example.demo")
        try FileManager.default.removeItem(at: container.appendingPathComponent(ContainerMetadata.fileName))
        let simulator = try XCTUnwrap(fixture.service.activeSimulators().first)
        XCTAssertTrue(fixture.service.installedApplications(on: simulator).isEmpty)
    }

    func testAppGroupsAndExtensionsFilterSystemContainers() throws {
        let device = try fixture.addDevice()
        try fixture.addSharedContainer(on: device, kind: "Shared/AppGroup", identifier: "group.com.example.shared")
        try fixture.addSharedContainer(on: device, kind: "Shared/AppGroup", identifier: "group.com.apple.notes")
        try fixture.addSharedContainer(on: device, kind: "Shared/AppGroup", identifier: "systemgroup.com.apple.configurationprofiles")
        try fixture.addSharedContainer(on: device, kind: "Data/PluginKitPlugin", identifier: "com.example.widget")
        try fixture.addSharedContainer(on: device, kind: "Data/PluginKitPlugin", identifier: "com.apple.widget")

        let simulator = try XCTUnwrap(fixture.service.activeSimulators().first)
        let content = fixture.service.content(of: simulator)
        XCTAssertEqual(content.appGroups.map(\.identifier), ["group.com.example.shared"])
        XCTAssertEqual(content.appExtensions.map(\.identifier), ["com.example.widget"])
        XCTAssertTrue(content.applications.isEmpty)
        XCTAssertFalse(content.isEmpty)
    }

    func testSimulatorWithOnlySystemContentIsEmpty() throws {
        let device = try fixture.addDevice()
        try fixture.installApp(on: device, bundleID: "com.apple.Preferences")
        try fixture.addSharedContainer(on: device, kind: "Shared/AppGroup", identifier: "group.com.apple.notes")

        let simulator = try XCTUnwrap(fixture.service.activeSimulators().first)
        XCTAssertTrue(fixture.service.content(of: simulator).isEmpty)
    }

    func testRealmFiles() throws {
        let device = try fixture.addDevice()
        let container = try fixture.installApp(on: device, bundleID: "com.example.realm")
        try Data().write(to: container.appendingPathComponent("Documents/default.realm"))
        try Data().write(to: container.appendingPathComponent("Library/Caches/cache.realm"))
        try Data().write(to: container.appendingPathComponent("Documents/notes.txt"))
        // 以 .realm 结尾的目录不是 Realm 数据库文件。
        try FileManager.default.createDirectory(
            at: container.appendingPathComponent("Documents/dir.realm"),
            withIntermediateDirectories: true
        )

        let files = SimulatorService.realmFiles(inContentPath: container.path)
        XCTAssertEqual(Set(files.map(\.fileName)), ["default.realm", "cache.realm"])
        XCTAssertTrue(files.allSatisfy { FileManager.default.fileExists(atPath: $0.fullPath) })
    }
}
