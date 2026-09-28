import Foundation

struct AppGroup {
    let uuid: String
    let path: String
    let identifier: String

    init?(entry: FileTools.FileEntry, simulator: Simulator) {
        uuid = entry.name
        path = simulator.appGroupPath(uuid: uuid)

        let plistPath = path + ".com.apple.mobile_container_manager.metadata.plist"
        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: plistPath)),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let identifier = plist["MCMMetadataIdentifier"] as? String else
        {
            return nil
        }
        self.identifier = identifier
    }

    var isAppleGroup: Bool {
        identifier.isEmpty
            || identifier.hasPrefix("com.apple")
            || identifier.hasPrefix("group.com.apple")
            || identifier.hasPrefix("group.is.workflow")
            || identifier.hasPrefix("243LU875E5.groups.com.apple")
    }
}
