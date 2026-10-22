@testable import SimBox
import XCTest

final class SimulatorTests: XCTestCase {
    func testReadableRuntime() {
        XCTAssertEqual(Simulator.readableRuntime(from: "com.apple.CoreSimulator.SimRuntime.iOS-27-0"), "iOS 27.0")
        XCTAssertEqual(Simulator.readableRuntime(from: "com.apple.CoreSimulator.SimRuntime.watchOS-11-2"), "watchOS 11.2")
        XCTAssertEqual(Simulator.readableRuntime(from: "com.apple.CoreSimulator.SimRuntime.tvOS-18-0"), "tvOS 18.0")
        XCTAssertEqual(Simulator.readableRuntime(from: "com.apple.CoreSimulator.SimRuntime.xrOS-2-0"), "xrOS 2.0")
        XCTAssertEqual(Simulator.readableRuntime(from: "com.apple.CoreSimulator.SimRuntime.iOS-17-0-1"), "iOS 17.0.1")
        XCTAssertEqual(Simulator.readableRuntime(from: nil), L10n.unknownOS)
        XCTAssertEqual(Simulator.readableRuntime(from: ""), L10n.unknownOS)
        XCTAssertEqual(Simulator.readableRuntime(from: "custom"), "custom")
    }

    func testParsesDevicePlist() throws {
        let fixture = try SimulatorFixture()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let folder = try fixture.addDevice(udid: "ABC", name: "iPhone 18 Pro", state: 3, lastUsedAt: date)

        let simulator = try XCTUnwrap(Simulator(devicePlistPath: folder.path + "/device.plist", folder: folder.path))
        XCTAssertEqual(simulator.udid, "ABC")
        XCTAssertEqual(simulator.name, "iPhone 18 Pro")
        XCTAssertEqual(simulator.runtime, "iOS 27.0")
        XCTAssertEqual(simulator.state, .booted)
        XCTAssertTrue(simulator.isBooted)
        XCTAssertFalse(simulator.isDeleted)
        XCTAssertEqual(simulator.lastUsedAt, date)
        // 传入的目录不带结尾斜杠时也要规范化，保证后续拼接路径正确。
        XCTAssertTrue(simulator.path.hasSuffix("/"))
        XCTAssertEqual(simulator.appGroupPath(uuid: "G"), simulator.path + "data/Containers/Shared/AppGroup/G/")
        XCTAssertEqual(simulator.displayTitle, "iPhone 18 Pro  ·  iOS 27.0  (\(L10n.booted))")
    }

    func testMissingPlistReturnsNil() {
        XCTAssertNil(Simulator(devicePlistPath: "/nonexistent/device.plist", folder: "/nonexistent/"))
    }

    func testUnknownStateAndDeletedFlag() throws {
        let fixture = try SimulatorFixture()
        let folder = try fixture.addDevice(state: 42, isDeleted: true)
        let simulator = try XCTUnwrap(Simulator(devicePlistPath: folder.path + "/device.plist", folder: folder.path))
        XCTAssertEqual(simulator.state, .unknown)
        XCTAssertTrue(simulator.isDeleted)
        XCTAssertFalse(simulator.displayTitle.contains(L10n.booted))
    }
}
