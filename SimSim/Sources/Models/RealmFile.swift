import Foundation

struct RealmFile {
    let fileName: String
    let folder: String

    var fullPath: String {
        let normalizedFolder = folder.hasSuffix("/") ? folder : folder + "/"
        return normalizedFolder + fileName
    }
}
