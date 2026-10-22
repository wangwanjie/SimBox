import Foundation

struct Simulator {
    enum State: Int {
        case creating = 0
        case shutdown = 1
        case booting = 2
        case booted = 3
        case shuttingDown = 4
        case unknown = -1
    }

    /// 模拟器根目录，统一以 `/` 结尾，便于直接拼接子路径。
    let path: String
    let udid: String
    let name: String
    let runtime: String
    let state: State
    let lastUsedAt: Date
    /// CoreSimulator 删除设备时可能先只打标记、稍后才清理目录，这类设备不应展示。
    let isDeleted: Bool

    init?(devicePlistPath: String, folder: String) {
        guard let properties = NSDictionary(contentsOfFile: devicePlistPath) as? [String: Any] else {
            return nil
        }
        path = folder.hasSuffix("/") ? folder : folder + "/"
        let folderName = URL(fileURLWithPath: folder).lastPathComponent
        udid = properties["UDID"] as? String ?? folderName
        name = properties["name"] as? String ?? L10n.unknownSimulator
        runtime = Simulator.readableRuntime(from: properties["runtime"] as? String)
        state = State(rawValue: properties["state"] as? Int ?? -1) ?? .unknown
        isDeleted = properties["isDeleted"] as? Bool ?? false

        // 新版 CoreSimulator 会写入 lastUsedAt；没有时退回目录修改时间。
        if let plistDate = properties["lastUsedAt"] as? Date {
            lastUsedAt = plistDate
        } else if let mod = (try? FileManager.default.attributesOfItem(atPath: folder))?[.modificationDate] as? Date {
            lastUsedAt = mod
        } else {
            lastUsedAt = .distantPast
        }
    }

    var displayTitle: String {
        let badge = state == .booted ? "  (\(L10n.booted))" : ""
        return "\(name)  ·  \(runtime)\(badge)"
    }

    var isBooted: Bool {
        state == .booted
    }

    var applicationDataRoot: String {
        path + "data/Containers/Data/Application/"
    }

    var applicationBundleRoot: String {
        path + "data/Containers/Bundle/Application/"
    }

    var appGroupRoot: String {
        path + "data/Containers/Shared/AppGroup/"
    }

    var appExtensionRoot: String {
        path + "data/Containers/Data/PluginKitPlugin/"
    }

    func applicationDataPath(uuid: String) -> String {
        applicationDataRoot + "\(uuid)/"
    }

    func appGroupPath(uuid: String) -> String {
        appGroupRoot + "\(uuid)/"
    }

    func appExtensionPath(uuid: String) -> String {
        appExtensionRoot + "\(uuid)/"
    }

    /// 把 `com.apple.CoreSimulator.SimRuntime.iOS-18-0` 转成 `iOS 18.0`。
    static func readableRuntime(from raw: String?) -> String {
        guard let raw, !raw.isEmpty else {
            return L10n.unknownOS
        }
        let trimmed = raw.replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
        // 第一个 `-` 之前是平台名，之后是以 `-` 分隔的版本号。
        guard let dashIndex = trimmed.firstIndex(of: "-") else {
            return trimmed
        }
        let platform = trimmed[..<dashIndex]
        let version = trimmed[trimmed.index(after: dashIndex)...].replacingOccurrences(of: "-", with: ".")
        return "\(platform) \(version)"
    }
}
