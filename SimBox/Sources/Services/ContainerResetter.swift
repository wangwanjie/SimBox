import Foundation

/// 清空模拟器容器里的用户数据，同时保留容器骨架。
///
/// 早期实现直接删掉 Documents / Library / tmp 目录本身：iOS 不会在 app 启动时重建这些目录，
/// 导致 app 往 Documents、Library/Caches 写文件失败；对 App Group 容器则基本无效。
/// 现在的做法是保留顶层目录，只删其中内容，并补回 `Library/Caches`、`Library/Preferences`。
struct ContainerResetter {
    /// 容器管理器的元数据与系统数据不能动，否则模拟器会认为容器损坏。
    static let preservedTopLevelNames: Set<String> = [ContainerMetadata.fileName, "SystemData"]
    static let recreatedLibrarySubfolders = ["Caches", "Preferences"]

    let fileManager: FileManager

    init(fileManager: FileManager = FileManager()) {
        self.fileManager = fileManager
    }

    /// - Returns: 删除失败的路径及原因，全部成功时为空数组。
    @discardableResult
    func reset(containerAt path: String) -> [(path: String, error: Error)] {
        let root = URL(fileURLWithPath: path, isDirectory: true)
        var failures: [(path: String, error: Error)] = []

        let children: [URL]
        do {
            children = try fileManager.contentsOfDirectory(at: root, includingPropertiesForKeys: [.isDirectoryKey])
        } catch {
            return [(path, error)]
        }

        for child in children where !Self.preservedTopLevelNames.contains(child.lastPathComponent) {
            let isDirectory = (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) ?? false
            if isDirectory {
                failures += removeContents(of: child)
            } else {
                failures += remove(child)
            }
        }

        let library = root.appendingPathComponent("Library", isDirectory: true)
        if fileManager.fileExists(atPath: library.path) {
            for name in Self.recreatedLibrarySubfolders {
                let folder = library.appendingPathComponent(name, isDirectory: true)
                do {
                    try fileManager.createDirectory(at: folder, withIntermediateDirectories: true)
                } catch {
                    failures.append((folder.path, error))
                }
            }
        }
        return failures
    }

    private func removeContents(of folder: URL) -> [(path: String, error: Error)] {
        let items: [URL]
        do {
            items = try fileManager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)
        } catch {
            return [(folder.path, error)]
        }
        return items.flatMap { remove($0) }
    }

    private func remove(_ url: URL) -> [(path: String, error: Error)] {
        do {
            try fileManager.removeItem(at: url)
            return []
        } catch {
            return [(url.path, error)]
        }
    }
}
