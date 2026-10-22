import AppKit
import Foundation

struct Application {
    let uuid: String
    /// 数据容器（Documents / Library / tmp 所在目录），以 `/` 结尾。
    let contentPath: String
    let bundleIdentifier: String
    /// `.app` 包的完整路径（以 `/` 结尾），找不到安装包时为 nil。
    let bundlePath: String?
    let info: BundleInfo

    var bundleName: String? {
        info.name
    }

    var displayTitle: String {
        let name = info.name ?? bundleIdentifier
        guard let version = info.displayVersion else {
            return name
        }
        return "\(name) \(version)"
    }

    var isAppleApplication: Bool {
        bundleIdentifier.hasPrefix("com.apple")
    }

    /// `NSUserDefaults.standard` 对应的 plist 文件。
    var preferencesPlistPath: String {
        contentPath + "Library/Preferences/\(bundleIdentifier).plist"
    }

    var icon: NSImage {
        AppIconLoader.icon(forBundleAt: bundlePath, info: info)
    }

    /// - Parameter bundleIndex: bundle ID → `.app` 路径的映射，由调用方对同一台模拟器只构建一次。
    init?(dataFolderEntry: FileTools.FileEntry, simulator: Simulator, bundleIndex: [String: String]) {
        uuid = dataFolderEntry.name
        contentPath = simulator.applicationDataPath(uuid: uuid)
        guard let identifier = ContainerMetadata.identifier(inContainer: contentPath) else {
            return nil
        }
        bundleIdentifier = identifier
        bundlePath = bundleIndex[identifier]

        if let bundlePath, let plist = NSDictionary(contentsOfFile: bundlePath + "Info.plist") as? [String: Any] {
            info = BundleInfo(plist: plist)
        } else {
            info = BundleInfo(plist: [:])
        }
    }

    /// 扫描 `Containers/Bundle/Application/`，建立 bundle ID → `.app` 路径的索引。
    static func bundleIndex(for simulator: Simulator) -> [String: String] {
        let bundleRoot = simulator.applicationBundleRoot
        var index: [String: String] = [:]
        for entry in FileTools.entries(in: bundleRoot) where entry.isDirectory {
            let containerRoot = bundleRoot + entry.name + "/"
            guard
                let identifier = ContainerMetadata.identifier(inContainer: containerRoot),
                let appFolderName = FileTools.firstAppBundleName(in: containerRoot) else {
                continue
            }
            index[identifier] = containerRoot + appFolderName + "/"
        }
        return index
    }
}

/// 从 `.app/Info.plist` 中解析出的展示信息，与文件系统解耦便于单测。
struct BundleInfo: Equatable {
    let name: String?
    let shortVersion: String?
    let buildVersion: String?
    /// 按优先级排列的图标文件基础名（不含 `@2x` 和扩展名）。
    let iconBaseNames: [String]
    /// 仅 iPad 应用的图标文件名带 `~ipad` 后缀。
    let iconSuffix: String

    init(plist: [String: Any]) {
        // 桌面上显示的是 CFBundleDisplayName，没有时才退回 CFBundleName。
        name = BundleInfo.nonEmpty(plist["CFBundleDisplayName"]) ?? BundleInfo.nonEmpty(plist["CFBundleName"])
        shortVersion = BundleInfo.nonEmpty(plist["CFBundleShortVersionString"])
        buildVersion = BundleInfo.nonEmpty(plist["CFBundleVersion"])

        var names: [String] = []
        var suffix = ""
        var iconsDict = plist["CFBundleIcons"] as? [String: Any]
        if iconsDict == nil {
            iconsDict = plist["CFBundleIcons~ipad"] as? [String: Any]
            suffix = iconsDict == nil ? "" : "~ipad"
        }
        if
            let primary = iconsDict?["CFBundlePrimaryIcon"] as? [String: Any],
            let files = primary["CFBundleIconFiles"] as? [String] {
            // 列表通常按尺寸从小到大排列，倒序后优先尝试大图。
            names.append(contentsOf: files.reversed())
        }
        if let legacyFiles = plist["CFBundleIconFiles"] as? [String] {
            names.append(contentsOf: legacyFiles.reversed())
        }
        if let single = BundleInfo.nonEmpty(plist["CFBundleIconFile"]) {
            names.append(single)
        }
        iconBaseNames = names.map { ($0 as NSString).deletingPathExtension }
        iconSuffix = suffix
    }

    /// 形如 `1.2.0 (45)`；两者相同或缺一时只显示一个。
    var displayVersion: String? {
        switch (shortVersion, buildVersion) {
        case (let short?, let build?) where short != build:
            "\(short) (\(build))"
        case (let short?, _):
            short
        case (nil, let build?):
            build
        case (nil, nil):
            nil
        }
    }

    /// 结合 iOS 图标命名规则生成候选文件名：`AppIcon60x60@2x.png`、`AppIcon76x76@2x~ipad.png`。
    var iconFileCandidates: [String] {
        var candidates: [String] = []
        for base in iconBaseNames {
            for scale in ["@2x", "@3x", ""] {
                candidates.append("\(base)\(scale)\(iconSuffix).png")
                if !iconSuffix.isEmpty {
                    candidates.append("\(base)\(scale).png")
                }
            }
        }
        return candidates
    }

    private static func nonEmpty(_ value: Any?) -> String? {
        guard let string = value as? String, !string.isEmpty else {
            return nil
        }
        return string
    }
}

/// 读取并缓存 app 图标，避免每次展开菜单都重新解码 PNG。
enum AppIconLoader {
    private static let cache = NSCache<NSString, NSImage>()

    static func icon(forBundleAt bundlePath: String?, info: BundleInfo) -> NSImage {
        let iconSize = NSSize(width: AppConfig.applicationIconSize, height: AppConfig.applicationIconSize)
        let fileManager = FileManager.default
        var iconPath: String?
        if let bundlePath {
            iconPath = info.iconFileCandidates
                .map { bundlePath + $0 }
                .first { fileManager.fileExists(atPath: $0) }
        }

        let cacheKey = (iconPath ?? "__fallback__") as NSString
        if let cached = cache.object(forKey: cacheKey) {
            return cached
        }
        let fallback = NSImage(named: "AppIconFallback") ?? NSImage(size: iconSize)
        let raw = iconPath.flatMap { NSImage(contentsOfFile: $0) } ?? fallback
        let result = raw.scaled(to: iconSize).withRoundedCorners(radius: 5)
        cache.setObject(result, forKey: cacheKey)
        return result
    }
}
