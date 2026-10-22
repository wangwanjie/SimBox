@testable import SimBox
import XCTest

final class ContainerResetterTests: XCTestCase {
    private let fm = FileManager.default

    func testResetEmptiesDataButKeepsSkeleton() throws {
        let fixture = try SimulatorFixture()
        let device = try fixture.addDevice()
        let container = try fixture.installApp(on: device, bundleID: "com.example.app")
        try Data("x".utf8).write(to: container.appendingPathComponent("Documents/user.db"))
        try fm.createDirectory(at: container.appendingPathComponent("Documents/Nested"), withIntermediateDirectories: true)
        try Data("x".utf8).write(to: container.appendingPathComponent("Library/Preferences/com.example.app.plist"))
        try Data("x".utf8).write(to: container.appendingPathComponent("tmp/scratch"))
        try Data("x".utf8).write(to: container.appendingPathComponent("SystemData/keep"))
        try Data("x".utf8).write(to: container.appendingPathComponent("stray.txt"))

        let failures = ContainerResetter().reset(containerAt: container.path)

        XCTAssertTrue(failures.isEmpty)
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: container.appendingPathComponent("Documents").path), [])
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: container.appendingPathComponent("tmp").path), [])
        XCTAssertEqual(
            try Set(fm.contentsOfDirectory(atPath: container.appendingPathComponent("Library").path)),
            ["Caches", "Preferences"]
        )
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: container.appendingPathComponent("Library/Preferences").path), [])
        XCTAssertFalse(fm.fileExists(atPath: container.appendingPathComponent("stray.txt").path))
        // 元数据和 SystemData 必须保留，否则模拟器会认为容器损坏。
        XCTAssertTrue(fm.fileExists(atPath: container.appendingPathComponent(ContainerMetadata.fileName).path))
        XCTAssertTrue(fm.fileExists(atPath: container.appendingPathComponent("SystemData/keep").path))
        XCTAssertEqual(ContainerMetadata.identifier(inContainer: container.path), "com.example.app")
    }

    func testResetAppGroupContainer() throws {
        let fixture = try SimulatorFixture()
        let device = try fixture.addDevice()
        let group = try fixture.addSharedContainer(on: device, kind: "Shared/AppGroup", identifier: "group.com.example")
        try Data("x".utf8).write(to: group.appendingPathComponent("Library/shared.sqlite"))
        try fm.createDirectory(at: group.appendingPathComponent("Custom"), withIntermediateDirectories: true)
        try Data("x".utf8).write(to: group.appendingPathComponent("Custom/file"))

        XCTAssertTrue(ContainerResetter().reset(containerAt: group.path).isEmpty)
        XCTAssertFalse(fm.fileExists(atPath: group.appendingPathComponent("Library/shared.sqlite").path))
        XCTAssertEqual(try fm.contentsOfDirectory(atPath: group.appendingPathComponent("Custom").path), [])
        XCTAssertTrue(fm.fileExists(atPath: group.appendingPathComponent("Library/Caches").path))
    }

    func testMissingContainerReportsFailure() {
        let failures = ContainerResetter().reset(containerAt: "/nonexistent-\(UUID().uuidString)")
        XCTAssertEqual(failures.count, 1)
    }
}
