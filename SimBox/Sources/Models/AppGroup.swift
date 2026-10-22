import Foundation

struct AppGroup {
    let uuid: String
    let path: String
    let identifier: String

    init?(entry: FileTools.FileEntry, simulator: Simulator) {
        uuid = entry.name
        path = simulator.appGroupPath(uuid: uuid)
        guard let identifier = ContainerMetadata.identifier(inContainer: path) else {
            return nil
        }
        self.identifier = identifier
    }

    var isAppleGroup: Bool {
        AppGroup.isAppleGroupIdentifier(identifier)
    }

    /// 系统自带的 App Group（含 Shortcuts 的 `group.is.workflow`）不展示给用户。
    static func isAppleGroupIdentifier(_ identifier: String) -> Bool {
        identifier.isEmpty
            || identifier.hasPrefix("com.apple")
            || identifier.hasPrefix("group.com.apple")
            || identifier.hasPrefix("group.is.workflow")
            || identifier.hasPrefix("243LU875E5.groups.com.apple")
            || identifier.hasPrefix("systemgroup.com.apple")
    }
}
