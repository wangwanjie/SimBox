import AppKit
import Foundation

struct Application {
    let uuid: String
    let contentPath: String
    let bundleIdentifier: String
    let bundleName: String?
    let version: String?
    let icon: NSImage?

    var displayTitle: String {
        let name = bundleName ?? bundleIdentifier
        let versionSuffix = version.map { " (\($0))" } ?? ""
        return name + versionSuffix
    }

    var isAppleApplication: Bool {
        bundleIdentifier.hasPrefix("com.apple")
    }

    init?(dataFolderEntry: FileTools.FileEntry, simulator: Simulator) {
        uuid = dataFolderEntry.name
        contentPath = simulator.path + "data/Containers/Data/Application/\(uuid)/"

        let metadataPath = contentPath + ".com.apple.mobile_container_manager.metadata.plist"
        guard let metadata = NSDictionary(contentsOfFile: metadataPath) as? [String: Any] else {
            return nil
        }
        bundleIdentifier = metadata["MCMMetadataIdentifier"] as? String ?? "unknown.bundle.identifier"

        let (name, version, icon) = Application.readBundleInfo(
            forBundleID: bundleIdentifier,
            simulatorRoot: simulator.path
        )
        bundleName = name
        self.version = version
        self.icon = icon
    }

    private static func readBundleInfo(
        forBundleID bundleID: String,
        simulatorRoot: String
    )
        -> (String?, String?, NSImage?)
    {
        let bundleFolder = simulatorRoot + "data/Containers/Bundle/Application/"
        for entry in FileTools.sortedEntries(in: bundleFolder) {
            let containerRoot = bundleFolder + entry.name + "/"
            let metadataPath = containerRoot + ".com.apple.mobile_container_manager.metadata.plist"
            guard
                let metadata = NSDictionary(contentsOfFile: metadataPath) as? [String: Any],
                let candidateID = metadata["MCMMetadataIdentifier"] as? String,
                candidateID == bundleID,
                let appFolderName = FileTools.firstAppBundleName(in: containerRoot) else { continue }

            let appFolder = containerRoot + appFolderName + "/"
            guard let plist = NSDictionary(contentsOfFile: appFolder + "Info.plist") as? [String: Any] else {
                return (nil, nil, nil)
            }
            let name = (plist["CFBundleName"] as? String).flatMap { $0.isEmpty ? nil : $0 }
                ?? plist["CFBundleDisplayName"] as? String
            let version = plist["CFBundleVersion"] as? String
            let icon = extractIcon(plist: plist, appFolder: appFolder)
            return (name, version, icon)
        }
        return (nil, nil, nil)
    }

    private static func extractIcon(plist: [String: Any], appFolder: String) -> NSImage {
        let iconSize = NSSize(width: AppConfig.applicationIconSize, height: AppConfig.applicationIconSize)
        let fallback = NSImage(named: "AppIconFallback") ?? NSImage(size: iconSize)

        var iconPath: String?
        if let single = plist["CFBundleIconFile"] as? String {
            iconPath = appFolder + single
        } else {
            var iconsDict = plist["CFBundleIcons"] as? [String: Any]
            var suffix = ""
            if iconsDict == nil {
                iconsDict = plist["CFBundleIcons~ipad"] as? [String: Any]
                suffix = "~ipad"
            }
            if
                let primary = iconsDict?["CFBundlePrimaryIcon"] as? [String: Any],
                let files = primary["CFBundleIconFiles"] as? [String],
                let last = files.last
            {
                let base = appFolder + "\(last)\(suffix)"
                let fm = FileManager.default
                for candidate in ["\(base).png", "\(base)@2x.png", "\(base)@3x.png"] {
                    if fm.fileExists(atPath: candidate) {
                        iconPath = candidate
                        break
                    }
                }
            }
        }

        let raw = iconPath.flatMap { NSImage(contentsOfFile: $0) } ?? fallback
        return raw.scaled(to: iconSize).withRoundedCorners(radius: 5)
    }
}
