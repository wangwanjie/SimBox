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

    let path: String
    let name: String
    let runtime: String
    let state: State
    let lastUsedAt: Date

    init?(devicePlistPath: String, folder: String) {
        guard let properties = NSDictionary(contentsOfFile: devicePlistPath) as? [String: Any] else {
            return nil
        }
        path = folder
        name = properties["name"] as? String ?? "Unknown Simulator"
        runtime = Simulator.readableRuntime(from: properties["runtime"] as? String)
        state = State(rawValue: properties["state"] as? Int ?? -1) ?? .unknown

        if let plistDate = properties["lastUsedAt"] as? Date {
            lastUsedAt = plistDate
        } else if let mod = (try? FileManager.default.attributesOfItem(atPath: folder))?[.modificationDate] as? Date {
            lastUsedAt = mod
        } else {
            lastUsedAt = .distantPast
        }
    }

    var displayTitle: String {
        let badge = state == .booted ? "  (Booted)" : ""
        return "\(name)  ·  \(runtime)\(badge)"
    }

    var isBooted: Bool {
        state == .booted
    }

    func appGroupPath(uuid: String) -> String {
        path + "data/Containers/Shared/AppGroup/\(uuid)/"
    }

    func appExtensionPath(uuid: String) -> String {
        path + "data/Containers/Data/PluginKitPlugin/\(uuid)/"
    }

    private static func readableRuntime(from raw: String?) -> String {
        guard let raw else { return "Unknown OS" }
        return raw
            .replacingOccurrences(of: "com.apple.CoreSimulator.SimRuntime.", with: "")
            .replacingOccurrences(of: "OS-", with: "OS ")
            .replacingOccurrences(of: "-", with: ".")
    }
}
