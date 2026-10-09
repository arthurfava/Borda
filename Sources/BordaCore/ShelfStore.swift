import Foundation

public final class ShelfStore {
    public enum StoreError: LocalizedError {
        case missingPayload(UUID)
        case invalidSource(URL)
        case missingShelf(UUID)
        case invalidItemOrder

        public var errorDescription: String? {
            switch self {
            case .missingPayload(let id): return CoreL10n.format("error.missing_payload", "The content for item %@ was not found.", id.uuidString)
            case .invalidSource(let url): return CoreL10n.format("error.invalid_source", "Couldn’t access %@.", url.path)
            case .missingShelf(let id): return CoreL10n.format("error.missing_shelf", "Shelf %@ was not found.", id.uuidString)
            case .invalidItemOrder: return CoreL10n.text("error.invalid_order", "The new order must contain exactly the items on the shelf.")
            }
        }
    }

    public private(set) var items: [ShelfItem]
    public private(set) var shelves: [ShelfGroup]
    public private(set) var exportHistory: [ShelfExportRecord]
    public let rootURL: URL

    private let fileManager: FileManager
    private let vaultURL: URL
    private let metadataURL: URL
    private let shelvesURL: URL
    private let exportHistoryURL: URL

    public init(rootURL: URL? = nil, fileManager: FileManager = .default) throws {
        self.fileManager = fileManager
        if let rootURL {
            self.rootURL = rootURL
        } else {
            self.rootURL = try BordaStorage.defaultRoot(fileManager: fileManager)
        }

        vaultURL = self.rootURL.appendingPathComponent("Vault", isDirectory: true)
        metadataURL = self.rootURL.appendingPathComponent("Shelf.json")
        shelvesURL = self.rootURL.appendingPathComponent("Shelves.json")
        exportHistoryURL = self.rootURL.appendingPathComponent("ExportHistory.json")
        items = []
        shelves = []
        exportHistory = []
        try fileManager.createDirectory(at: vaultURL, withIntermediateDirectories: true)

        items = try Self.load([ShelfItem].self, from: metadataURL, fileManager: fileManager) ?? []
        items = items.filter { fileManager.fileExists(atPath: payloadURL(for: $0).path) }

        shelves = try Self.load([ShelfGroup].self, from: shelvesURL, fileManager: fileManager) ?? []
        let activeIDs = Set(items.map(\.id))
        shelves = shelves.compactMap { shelf in
            var valid = shelf
            valid.itemIDs = shelf.itemIDs.filter(activeIDs.contains)
            return valid.itemIDs.isEmpty ? nil : valid
        }

        let assignedIDs = Set(shelves.flatMap(\.itemIDs))
        let orphanIDs = items.map(\.id).filter { !assignedIDs.contains($0) }
        if !orphanIDs.isEmpty {
            if shelves.isEmpty {
                shelves.append(ShelfGroup(side: .right, normalizedY: 0.5, itemIDs: orphanIDs))
            } else {
                shelves[0].itemIDs.append(contentsOf: orphanIDs)
            }
        }

        do {
            let records = try Self.load([ShelfExportRecord].self, from: exportHistoryURL, fileManager: fileManager) ?? []
            exportHistory = records.filter {
                !activeIDs.contains($0.item.id) && fileManager.fileExists(atPath: payloadURL(for: $0.item).path)
            }
        } catch {
            guard let legacy = try? Self.load([ShelfItem].self, from: exportHistoryURL, fileManager: fileManager) else {
                throw error
            }
            let fallback = ShelfGroup(side: .right, normalizedY: 0.5)
            exportHistory = legacy
                .filter { !activeIDs.contains($0.id) && fileManager.fileExists(atPath: payloadURL(for: $0).path) }
                .map { ShelfExportRecord(item: $0, shelf: fallback) }
        }
        try persist()
    }

    @discardableResult
    public func createShelf(side: ShelfSide, screenID: String?, normalizedY: Double) throws -> ShelfGroup {
        let shelf = ShelfGroup(side: side, screenID: screenID, normalizedY: normalizedY)
        shelves.append(shelf)
        try persist()
        return shelf
    }

    public func shelf(withID id: UUID) -> ShelfGroup? { shelves.first { $0.id == id } }

    public var openShelves: [ShelfGroup] { shelves.filter { !$0.isClosed } }

    public var recentShelves: [ShelfGroup] {
        shelves.filter(\.isClosed).sorted { $0.updatedAt > $1.updatedAt }
    }

    public func items(inShelf id: UUID) -> [ShelfItem] {
        guard let shelf = shelf(withID: id) else { return [] }
        let index = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        return shelf.itemIDs.compactMap { index[$0] }
    }

    public func updateShelf(_ id: UUID, side: ShelfSide, screenID: String?, normalizedY: Double) throws {
        guard let index = shelves.firstIndex(where: { $0.id == id }) else { throw StoreError.missingShelf(id) }
        shelves[index].side = side
        shelves[index].screenID = screenID
        shelves[index].normalizedY = min(max(normalizedY, 0), 1)
        touchShelf(at: index)
        try persist()
    }

    public func updateShelfIdentity(_ id: UUID, name: String?, color: ShelfColor) throws {
        guard let index = shelves.firstIndex(where: { $0.id == id }) else { throw StoreError.missingShelf(id) }
        let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines)
        shelves[index].name = trimmed?.isEmpty == false ? trimmed : nil
        shelves[index].color = color
        touchShelf(at: index)
        try persist()
    }

    public func setShelfPinned(_ id: UUID, pinned: Bool) throws {
        guard let index = shelves.firstIndex(where: { $0.id == id }) else { throw StoreError.missingShelf(id) }
        shelves[index].isPinned = pinned
        touchShelf(at: index)
        try persist()
    }

    public func reorderItems(inShelf id: UUID, orderedIDs: [UUID]) throws {
        guard let index = shelves.firstIndex(where: { $0.id == id }) else { throw StoreError.missingShelf(id) }
        guard orderedIDs.count == shelves[index].itemIDs.count,
              Set(orderedIDs) == Set(shelves[index].itemIDs) else { throw StoreError.invalidItemOrder }
        shelves[index].itemIDs = orderedIDs
        touchShelf(at: index)
        try persist()
    }

    public func closeShelf(_ id: UUID) throws {
        guard let index = shelves.firstIndex(where: { $0.id == id }) else { throw StoreError.missingShelf(id) }
        shelves[index].isClosed = true
        touchShelf(at: index)
        try persist()
    }

    public func reopenShelf(_ id: UUID) throws {
        guard let index = shelves.firstIndex(where: { $0.id == id }) else { throw StoreError.missingShelf(id) }
        shelves[index].isClosed = false
        touchShelf(at: index)
        try persist()
    }

    public func discardShelfIfEmpty(_ id: UUID) throws {
        guard let shelf = shelf(withID: id), shelf.itemIDs.isEmpty else { return }
        shelves.removeAll { $0.id == id }
        try persist()
    }

    @discardableResult
    public func addFile(at sourceURL: URL, toShelf shelfID: UUID) throws -> ShelfItem {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: sourceURL.path, isDirectory: &isDirectory) else {
            throw StoreError.invalidSource(sourceURL)
        }
        let id = UUID()
        let itemDirectory = vaultURL.appendingPathComponent(id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: itemDirectory, withIntermediateDirectories: true)
        let originalName = sourceURL.lastPathComponent.isEmpty ? CoreL10n.text("kind.item", "Item") : sourceURL.lastPathComponent
        let payload = itemDirectory.appendingPathComponent(originalName, isDirectory: isDirectory.boolValue)
        do { try fileManager.copyItem(at: sourceURL, to: payload) } catch {
            try? fileManager.removeItem(at: itemDirectory)
            throw error
        }
        let values = try? payload.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
        let item = ShelfItem(
            id: id,
            kind: isDirectory.boolValue ? .folder : Self.kind(for: sourceURL),
            displayName: originalName,
            storedFileName: originalName,
            byteCount: Int64(values?.totalFileAllocatedSize ?? values?.fileAllocatedSize ?? 0)
        )
        do { try append(item, toShelf: shelfID) } catch {
            try? fileManager.removeItem(at: itemDirectory)
            throw error
        }
        return item
    }

    @discardableResult
    public func addText(_ text: String, toShelf shelfID: UUID) throws -> ShelfItem {
        let preview = text.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        return try addData(Data(text.utf8), fileName: "Text.txt", kind: .text,
                           displayName: preview.isEmpty ? CoreL10n.text("kind.text", "Text") : String(preview.prefix(48)), toShelf: shelfID)
    }

    @discardableResult
    public func addURL(_ url: URL, toShelf shelfID: UUID) throws -> ShelfItem {
        try addData(Data(url.absoluteString.utf8), fileName: "Link.url", kind: .url,
                    displayName: url.host ?? url.absoluteString, toShelf: shelfID)
    }

    @discardableResult
    public func addData(_ data: Data, fileName: String, kind: ShelfItem.Kind, displayName: String, toShelf shelfID: UUID) throws -> ShelfItem {
        let id = UUID()
        let itemDirectory = vaultURL.appendingPathComponent(id.uuidString, isDirectory: true)
        try fileManager.createDirectory(at: itemDirectory, withIntermediateDirectories: true)
        let payload = itemDirectory.appendingPathComponent(fileName)
        do { try data.write(to: payload, options: .atomic) } catch {
            try? fileManager.removeItem(at: itemDirectory)
            throw error
        }
        let item = ShelfItem(id: id, kind: kind, displayName: displayName, storedFileName: fileName, byteCount: Int64(data.count))
        do { try append(item, toShelf: shelfID) } catch {
            try? fileManager.removeItem(at: itemDirectory)
            throw error
        }
        return item
    }

    public func remove(_ item: ShelfItem, fromShelf shelfID: UUID) throws {
        let directory = vaultURL.appendingPathComponent(item.id.uuidString, isDirectory: true)
        if fileManager.fileExists(atPath: directory.path) { try fileManager.removeItem(at: directory) }
        items.removeAll { $0.id == item.id }
        exportHistory.removeAll { $0.item.id == item.id }
        removeItemID(item.id, fromShelf: shelfID)
        try persist()
    }

    @discardableResult
    public func rename(_ item: ShelfItem, to requestedName: String) throws -> ShelfItem {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { throw StoreError.missingPayload(item.id) }
        let trimmed = requestedName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return item }
        let oldURL = payloadURL(for: item)
        let oldExtension = oldURL.pathExtension
        let suppliedExtension = URL(fileURLWithPath: trimmed).pathExtension
        let fileName = suppliedExtension.isEmpty && !oldExtension.isEmpty ? "\(trimmed).\(oldExtension)" : trimmed
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(fileName)
        if newURL != oldURL { try fileManager.moveItem(at: oldURL, to: newURL) }
        let replacement = ShelfItem(id: item.id, kind: item.kind, displayName: trimmed,
                                    storedFileName: fileName, createdAt: item.createdAt, byteCount: item.byteCount)
        items[index] = replacement
        try persist()
        return replacement
    }

    public func markExported(_ item: ShelfItem, fromShelf shelfID: UUID) throws {
        guard let shelf = shelf(withID: shelfID), items.contains(where: { $0.id == item.id }) else { return }
        items.removeAll { $0.id == item.id }
        removeItemID(item.id, fromShelf: shelfID)
        exportHistory.removeAll { $0.item.id == item.id }
        exportHistory.append(ShelfExportRecord(item: item, shelf: shelf))
        try persist()
    }

    @discardableResult
    public func restoreLastExported() throws -> ShelfRestoreResult? {
        guard let record = exportHistory.popLast() else { return nil }
        guard fileManager.fileExists(atPath: payloadURL(for: record.item).path) else {
            try persist()
            throw StoreError.missingPayload(record.item.id)
        }
        items.append(record.item)
        if let index = shelves.firstIndex(where: { $0.id == record.shelfID }) {
            shelves[index].itemIDs.append(record.item.id)
        } else {
            shelves.append(ShelfGroup(id: record.shelfID, side: record.side, screenID: record.screenID,
                                      normalizedY: record.normalizedY, itemIDs: [record.item.id],
                                      name: record.shelfName, color: record.shelfColor, isPinned: record.shelfWasPinned))
        }
        try persist()
        return ShelfRestoreResult(item: record.item, shelfID: record.shelfID)
    }

    public var canRestoreExportedItem: Bool { !exportHistory.isEmpty }

    public func payloadURL(for item: ShelfItem) -> URL {
        vaultURL.appendingPathComponent(item.id.uuidString, isDirectory: true)
            .appendingPathComponent(item.storedFileName, isDirectory: item.kind == .folder)
    }

    public func text(for item: ShelfItem) -> String? {
        guard item.kind == .text || item.kind == .url else { return nil }
        return try? String(contentsOf: payloadURL(for: item), encoding: .utf8)
    }

    private func append(_ item: ShelfItem, toShelf shelfID: UUID) throws {
        guard let shelfIndex = shelves.firstIndex(where: { $0.id == shelfID }) else { throw StoreError.missingShelf(shelfID) }
        items.append(item)
        shelves[shelfIndex].itemIDs.append(item.id)
        shelves[shelfIndex].isClosed = false
        touchShelf(at: shelfIndex)
        try persist()
    }

    private func removeItemID(_ itemID: UUID, fromShelf shelfID: UUID) {
        guard let shelfIndex = shelves.firstIndex(where: { $0.id == shelfID }) else { return }
        shelves[shelfIndex].itemIDs.removeAll { $0 == itemID }
        if shelves[shelfIndex].itemIDs.isEmpty { shelves.remove(at: shelfIndex) }
    }

    private func touchShelf(at index: Int) {
        shelves[index].updatedAt = Date(timeIntervalSince1970: (Date().timeIntervalSince1970 * 1_000).rounded(.down) / 1_000)
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .millisecondsSince1970
        try encoder.encode(items).write(to: metadataURL, options: .atomic)
        try encoder.encode(shelves).write(to: shelvesURL, options: .atomic)
        try encoder.encode(exportHistory).write(to: exportHistoryURL, options: .atomic)
    }

    private static func load<T: Decodable>(_ type: T.Type, from url: URL, fileManager: FileManager) throws -> T? {
        guard fileManager.fileExists(atPath: url.path) else { return nil }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(T.self, from: Data(contentsOf: url))
    }

    private static func kind(for url: URL) -> ShelfItem.Kind {
        let images = Set(["png", "jpg", "jpeg", "gif", "heic", "heif", "tiff", "webp"])
        return images.contains(url.pathExtension.lowercased()) ? .image : .file
    }
}
