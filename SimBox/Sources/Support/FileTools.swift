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

    /// 列出目录下的条目，跳过 `.DS_Store` 等隐藏文件。
    static func entries(in folder: String) -> [FileEntry] {
        let fm = FileManager.default
        let base = folder.hasSuffix("/") ? folder : folder + "/"
        return contents(of: folder)
            .filter { !$0.hasPrefix(".") }
            .compactMap { name -> FileEntry? in
                let fullPath = base + name
                guard let attrs = try? fm.attributesOfItem(atPath: fullPath) else {
                    return nil
                }
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

    /// 按修改时间排序，默认最近修改的排在前面。
    static func sortedEntries(in folder: String, newestFirst: Bool = true) -> [FileEntry] {
        entries(in: folder).sorted { lhs, rhs in
            if lhs.modificationDate == rhs.modificationDate {
                return lhs.name < rhs.name
            }
            return newestFirst ? lhs.modificationDate > rhs.modificationDate : lhs.modificationDate < rhs.modificationDate
        }
    }

    static func firstAppBundleName(in folder: String) -> String? {
        contents(of: folder).sorted().first { URL(fileURLWithPath: $0).pathExtension == "app" }
    }

    static func hasVisibleEntries(in folder: String) -> Bool {
        contents(of: folder).contains { !$0.hasPrefix(".") }
    }
}
