@testable import SimBox
import XCTest

/// 检查 String Catalog 完整性：代码里用到的每个 key 都在 catalog 中，且三种语言都已翻译。
final class LocalizationTests: XCTestCase {
    private static let languages = ["en", "zh-Hans", "zh-Hant"]

    /// 仓库根目录，通过本文件路径推算，避免依赖测试运行时的工作目录。
    private var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
    }

    private func loadCatalog() throws -> [String: [String: Any]] {
        let url = repositoryRoot.appendingPathComponent("SimBox/Resources/Localizable.xcstrings")
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
        return try XCTUnwrap(json?["strings"] as? [String: [String: Any]])
    }

    private func value(in entry: [String: Any], language: String) -> String? {
        let localizations = entry["localizations"] as? [String: Any]
        let unit = (localizations?[language] as? [String: Any])?["stringUnit"] as? [String: Any]
        guard unit?["state"] as? String == "translated" else {
            return nil
        }
        return unit?["value"] as? String
    }

    private func placeholderCount(_ string: String) -> Int {
        string.components(separatedBy: "%@").count - 1
    }

    func testEveryCatalogEntryIsTranslated() throws {
        let catalog = try loadCatalog()
        XCTAssertFalse(catalog.isEmpty)
        for (key, entry) in catalog {
            for language in Self.languages {
                let translated = value(in: entry, language: language)
                XCTAssertNotNil(translated, "\(key) 缺少 \(language) 翻译")
                if let translated {
                    XCTAssertFalse(translated.isEmpty, "\(key) 的 \(language) 翻译为空")
                    XCTAssertEqual(placeholderCount(translated), placeholderCount(key), "\(key) 的 \(language) 占位符数量不一致")
                }
            }
        }
    }

    func testEverySourceKeyExistsInCatalog() throws {
        let catalog = try loadCatalog()
        let sourceRoot = repositoryRoot.appendingPathComponent("SimBox/Sources")
        let enumerator = try XCTUnwrap(FileManager.default.enumerator(at: sourceRoot, includingPropertiesForKeys: nil))
        let literal = try NSRegularExpression(pattern: #"String\(\s*localized:\s*"((?:[^"\\]|\\.)*)""#)
        let interpolation = try NSRegularExpression(pattern: #"\\\([^)]*\)"#)

        var keys: Set<String> = []
        for case let url as URL in enumerator where url.pathExtension == "swift" {
            let source = try String(contentsOf: url, encoding: .utf8)
            let range = NSRange(source.startIndex..., in: source)
            for match in literal.matches(in: source, range: range) {
                guard let keyRange = Range(match.range(at: 1), in: source) else {
                    continue
                }
                // 把 Swift 源码中的插值和转义还原成 catalog 中的 key 形式。
                var key = String(source[keyRange])
                key = interpolation.stringByReplacingMatches(
                    in: key,
                    range: NSRange(key.startIndex..., in: key),
                    withTemplate: "%@"
                )
                key = key.replacingOccurrences(of: "\\n", with: "\n").replacingOccurrences(of: "\\\"", with: "\"")
                keys.insert(key)
            }
        }

        XCTAssertFalse(keys.isEmpty)
        for key in keys {
            XCTAssertNotNil(catalog[key], "catalog 缺少 key: \(key)")
        }
        // 反向检查：catalog 里不应残留代码已不再使用的 key。
        XCTAssertEqual(Set(catalog.keys).subtracting(keys), [])
    }

    func testCompiledBundleContainsChineseLocalizations() throws {
        XCTAssertTrue(Bundle.main.localizations.contains("zh-Hans"))
        XCTAssertTrue(Bundle.main.localizations.contains("zh-Hant"))

        let expectations: [(language: String, key: String, value: String)] = [
            ("zh-Hans", "Copy path", "拷贝路径"),
            ("zh-Hant", "Copy path", "拷貝路徑"),
            ("zh-Hans", "Finder", "访达"),
            ("en", "Quit SimBox", "Quit SimBox")
        ]
        for expectation in expectations {
            let path = try XCTUnwrap(Bundle.main.path(forResource: expectation.language, ofType: "lproj"))
            let bundle = try XCTUnwrap(Bundle(path: path))
            XCTAssertEqual(
                bundle.localizedString(forKey: expectation.key, value: "<missing>", table: "Localizable"),
                expectation.value
            )
        }
    }
}
