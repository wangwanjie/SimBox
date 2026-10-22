@testable import SimBox
import XCTest

final class BundleInfoTests: XCTestCase {
    func testPrefersDisplayName() {
        let info = BundleInfo(plist: ["CFBundleDisplayName": "示例", "CFBundleName": "ExampleiOS"])
        XCTAssertEqual(info.name, "示例")
    }

    func testFallsBackToBundleNameWhenDisplayNameEmpty() {
        let info = BundleInfo(plist: ["CFBundleDisplayName": "", "CFBundleName": "ExampleiOS"])
        XCTAssertEqual(info.name, "ExampleiOS")
    }

    func testDisplayVersion() {
        XCTAssertEqual(BundleInfo(plist: ["CFBundleShortVersionString": "1.2", "CFBundleVersion": "45"]).displayVersion, "1.2 (45)")
        XCTAssertEqual(BundleInfo(plist: ["CFBundleShortVersionString": "1.2", "CFBundleVersion": "1.2"]).displayVersion, "1.2")
        XCTAssertEqual(BundleInfo(plist: ["CFBundleShortVersionString": "1.2"]).displayVersion, "1.2")
        XCTAssertEqual(BundleInfo(plist: ["CFBundleVersion": "7"]).displayVersion, "7")
        XCTAssertNil(BundleInfo(plist: [:]).displayVersion)
    }

    func testIPhoneIconCandidatesPreferLargestAndRetina() {
        let info = BundleInfo(plist: [
            "CFBundleIcons": ["CFBundlePrimaryIcon": ["CFBundleIconFiles": ["AppIcon20x20", "AppIcon60x60"]]]
        ])
        XCTAssertEqual(info.iconBaseNames, ["AppIcon60x60", "AppIcon20x20"])
        XCTAssertEqual(info.iconFileCandidates.first, "AppIcon60x60@2x.png")
        XCTAssertTrue(info.iconFileCandidates.contains("AppIcon20x20.png"))
    }

    func testIPadIconSuffixGoesAfterScale() {
        let info = BundleInfo(plist: [
            "CFBundleIcons~ipad": ["CFBundlePrimaryIcon": ["CFBundleIconFiles": ["AppIcon76x76"]]]
        ])
        XCTAssertEqual(info.iconSuffix, "~ipad")
        XCTAssertEqual(info.iconFileCandidates.first, "AppIcon76x76@2x~ipad.png")
        XCTAssertFalse(info.iconFileCandidates.contains("AppIcon76x76~ipad@2x.png"))
    }

    func testLegacyIconFileStripsExtension() {
        let info = BundleInfo(plist: ["CFBundleIconFile": "Icon.png"])
        XCTAssertEqual(info.iconBaseNames, ["Icon"])
        XCTAssertTrue(info.iconFileCandidates.contains("Icon.png"))
    }
}
