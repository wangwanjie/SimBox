import Foundation

struct AppExtension {
    let uuid: String
    let path: String
    let identifier: String

    init?(entry: FileTools.FileEntry, simulator: Simulator) {
        uuid = entry.name
        path = simulator.appExtensionPath(uuid: uuid)
        guard let identifier = ContainerMetadata.identifier(inContainer: path) else {
            return nil
        }
        self.identifier = identifier
    }

    var isAppleExtension: Bool {
        identifier.hasPrefix("com.apple")
    }
}
