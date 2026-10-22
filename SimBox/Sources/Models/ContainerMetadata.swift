import Foundation

/// 模拟器每个容器目录下都有一份 `.com.apple.mobile_container_manager.metadata.plist`，
/// 其中 `MCMMetadataIdentifier` 记录了容器对应的 bundle ID / App Group ID。
enum ContainerMetadata {
    static let fileName = ".com.apple.mobile_container_manager.metadata.plist"

    static func identifier(inContainer containerPath: String) -> String? {
        let normalized = containerPath.hasSuffix("/") ? containerPath : containerPath + "/"
        guard
            let data = FileManager.default.contents(atPath: normalized + fileName),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
            let identifier = plist["MCMMetadataIdentifier"] as? String else {
            return nil
        }
        return identifier
    }
}
