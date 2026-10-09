import Foundation

public enum BordaStorage {
    public static let appGroupIdentifier = "group.com.arthurfava.Borda"

    public static func defaultRoot(fileManager: FileManager = .default) throws -> URL {
        if let group = fileManager.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) {
            let root = group.appendingPathComponent("Library/Application Support/Borda", isDirectory: true)
            try migrateLegacyDataIfNeeded(to: root, fileManager: fileManager)
            return root
        }

        let applicationSupport = try fileManager.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        return applicationSupport.appendingPathComponent("Borda", isDirectory: true)
    }

    public static func migrateLegacyDataIfNeeded(to destination: URL, fileManager: FileManager = .default) throws {
        let legacy = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Borda", isDirectory: true)
        guard legacy.standardizedFileURL != destination.standardizedFileURL,
              fileManager.fileExists(atPath: legacy.path) else { return }

        let destinationHasData = ["Shelf.json", "Shelves.json", "ExportHistory.json"]
            .contains { fileManager.fileExists(atPath: destination.appendingPathComponent($0).path) }
        guard !destinationHasData else { return }

        try fileManager.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        if fileManager.fileExists(atPath: destination.path) {
            for child in try fileManager.contentsOfDirectory(at: legacy, includingPropertiesForKeys: nil) {
                let target = destination.appendingPathComponent(child.lastPathComponent)
                guard !fileManager.fileExists(atPath: target.path) else { continue }
                try fileManager.copyItem(at: child, to: target)
            }
        } else {
            try fileManager.copyItem(at: legacy, to: destination)
        }
    }
}
