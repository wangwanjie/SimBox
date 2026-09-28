import Foundation

enum FileTools {
    struct FileEntry {
        let name: String
        let path: String
        let modificationDate: Date
        let isDirectory: Bool
    }

    static func homeDirectory() -> URL {
        URL(fileURLWithPath: NSHomeDirectory())
    }

    static func contents(of folder: String) -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: folder)) ?? []
    }

    static func entries(in folder: String) -> [FileEntry] {
        let fm = FileManager.default
        return contents(of: folder)
            .filter { $0 != AppConfig.OtherPath.dsStore }
            .compactMap { name -> FileEntry? in
                let fullPath = folder + "/" + name
                guard let attrs = try? fm.attributesOfItem(atPath: fullPath) else { return nil }
                let date = attrs[.modificationDate] as? Date ?? .distantPast
                let type = attrs[.type] as? FileAttributeType
                return FileEntry(
                    name: name,
                    path: fullPath,
                    modificationDate: date,
                    isDirectory: type == .typeDirectory
                )
            }
    }

    static func sortedEntries(in folder: String) -> [FileEntry] {
        entries(in: folder).sorted { $0.modificationDate < $1.modificationDate }
    }

    static func firstAppBundleName(in folder: String) -> String? {
        contents(of: folder).first { URL(fileURLWithPath: $0).pathExtension == "app" }
    }
}
