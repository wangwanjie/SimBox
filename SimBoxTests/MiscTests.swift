@testable import SimBox
import XCTest

final class UpdateFeedTests: XCTestCase {
    func testArchitectureSpecificFeed() {
        let base = "https://raw.githubusercontent.com/wangwanjie/SimBox/master/appcast.xml"
        XCTAssertEqual(
            UpdateFeed.feedURLString(baseFeedURL: base, architecture: "arm64"),
            "https://raw.githubusercontent.com/wangwanjie/SimBox/master/appcast-arm64.xml"
        )
        XCTAssertEqual(
            UpdateFeed.feedURLString(baseFeedURL: base, architecture: "x86_64"),
            "https://raw.githubusercontent.com/wangwanjie/SimBox/master/appcast-x86_64.xml"
        )
        XCTAssertNil(UpdateFeed.feedURLString(baseFeedURL: nil, architecture: "arm64"))
        XCTAssertNil(UpdateFeed.feedURLString(baseFeedURL: "https://example.com/feed", architecture: "arm64"))
    }

    func testCurrentArchitectureMatchesBuild() {
        #if arch(arm64)
            XCTAssertEqual(UpdateFeed.currentArchitecture, "arm64")
        #else
            XCTAssertEqual(UpdateFeed.currentArchitecture, "x86_64")
        #endif
    }

    func testInfoPlistFeedPointsToRepository() throws {
        let feed = try XCTUnwrap(Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") as? String)
        XCTAssertTrue(feed.hasSuffix("/appcast.xml"))
        XCTAssertNotNil(Bundle.main.object(forInfoDictionaryKey: "SUPublicEDKey"))
    }
}

final class AppGroupTests: XCTestCase {
    func testAppleGroupDetection() {
        XCTAssertTrue(AppGroup.isAppleGroupIdentifier(""))
        XCTAssertTrue(AppGroup.isAppleGroupIdentifier("group.com.apple.notes"))
        XCTAssertTrue(AppGroup.isAppleGroupIdentifier("group.is.workflow.shortcuts"))
        XCTAssertTrue(AppGroup.isAppleGroupIdentifier("systemgroup.com.apple.lsd"))
        XCTAssertFalse(AppGroup.isAppleGroupIdentifier("group.com.example.app"))
    }
}

final class FileToolsTests: XCTestCase {
    func testSortedEntriesNewestFirstAndSkipsHiddenFiles() throws {
        let fixture = try SimulatorFixture()
        let folder = fixture.root.appendingPathComponent("entries")
        let fm = FileManager.default
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        for (name, time) in [("a", 100.0), ("b", 300.0), ("c", 200.0), (".DS_Store", 400.0)] {
            let url = folder.appendingPathComponent(name)
            try Data().write(to: url)
            try fm.setAttributes([.modificationDate: Date(timeIntervalSince1970: time)], ofItemAtPath: url.path)
        }
        XCTAssertEqual(FileTools.sortedEntries(in: folder.path).map(\.name), ["b", "c", "a"])
        XCTAssertEqual(FileTools.sortedEntries(in: folder.path, newestFirst: false).map(\.name), ["a", "c", "b"])
        XCTAssertTrue(FileTools.sortedEntries(in: "/nonexistent-\(UUID().uuidString)").isEmpty)
    }

    func testRealmFileFullPath() {
        XCTAssertEqual(RealmFile(fileName: "a.realm", folder: "/x").fullPath, "/x/a.realm")
        XCTAssertEqual(RealmFile(fileName: "a.realm", folder: "/x/").fullPath, "/x/a.realm")
    }
}
