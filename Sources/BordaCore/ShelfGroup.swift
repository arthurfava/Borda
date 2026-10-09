import Foundation

public enum ShelfSide: String, Codable, CaseIterable, Sendable {
    case left
    case right
}

public enum ShelfColor: String, Codable, CaseIterable, Sendable {
    case neutral
    case blue
    case violet
    case pink
    case orange
    case green
}

public struct ShelfGroup: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public var side: ShelfSide
    public var screenID: String?
    public var normalizedY: Double
    public var itemIDs: [UUID]
    public var name: String?
    public var color: ShelfColor
    public var isPinned: Bool
    public var isClosed: Bool
    public let createdAt: Date
    public var updatedAt: Date

    public init(id: UUID = UUID(), side: ShelfSide, screenID: String? = nil, normalizedY: Double,
                itemIDs: [UUID] = [], name: String? = nil, color: ShelfColor = .neutral,
                isPinned: Bool = false, isClosed: Bool = false, createdAt: Date = Date(),
                updatedAt: Date? = nil) {
        self.id = id
        self.side = side
        self.screenID = screenID
        self.normalizedY = min(max(normalizedY, 0), 1)
        self.itemIDs = itemIDs
        self.name = name
        self.color = color
        self.isPinned = isPinned
        self.isClosed = isClosed
        self.createdAt = Date(timeIntervalSince1970: (createdAt.timeIntervalSince1970 * 1_000).rounded(.down) / 1_000)
        let modified = updatedAt ?? createdAt
        self.updatedAt = Date(timeIntervalSince1970: (modified.timeIntervalSince1970 * 1_000).rounded(.down) / 1_000)
    }

    private enum CodingKeys: String, CodingKey {
        case id, side, screenID, normalizedY, itemIDs, name, color, isPinned, isClosed, createdAt, updatedAt
    }

    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        id = try values.decode(UUID.self, forKey: .id)
        side = try values.decode(ShelfSide.self, forKey: .side)
        screenID = try values.decodeIfPresent(String.self, forKey: .screenID)
        normalizedY = min(max(try values.decode(Double.self, forKey: .normalizedY), 0), 1)
        itemIDs = try values.decodeIfPresent([UUID].self, forKey: .itemIDs) ?? []
        name = try values.decodeIfPresent(String.self, forKey: .name)
        color = try values.decodeIfPresent(ShelfColor.self, forKey: .color) ?? .neutral
        isPinned = try values.decodeIfPresent(Bool.self, forKey: .isPinned) ?? false
        isClosed = try values.decodeIfPresent(Bool.self, forKey: .isClosed) ?? false
        createdAt = try values.decode(Date.self, forKey: .createdAt)
        updatedAt = try values.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

public struct ShelfExportRecord: Codable, Equatable, Sendable {
    public let item: ShelfItem
    public let shelfID: UUID
    public let side: ShelfSide
    public let screenID: String?
    public let normalizedY: Double
    public let shelfName: String?
    public let shelfColor: ShelfColor
    public let shelfWasPinned: Bool

    public init(item: ShelfItem, shelf: ShelfGroup) {
        self.item = item
        shelfID = shelf.id
        side = shelf.side
        screenID = shelf.screenID
        normalizedY = shelf.normalizedY
        shelfName = shelf.name
        shelfColor = shelf.color
        shelfWasPinned = shelf.isPinned
    }

    private enum CodingKeys: String, CodingKey { case item, shelfID, side, screenID, normalizedY, shelfName, shelfColor, shelfWasPinned }
    public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        item = try values.decode(ShelfItem.self, forKey: .item)
        shelfID = try values.decode(UUID.self, forKey: .shelfID)
        side = try values.decode(ShelfSide.self, forKey: .side)
        screenID = try values.decodeIfPresent(String.self, forKey: .screenID)
        normalizedY = try values.decode(Double.self, forKey: .normalizedY)
        shelfName = try values.decodeIfPresent(String.self, forKey: .shelfName)
        shelfColor = try values.decodeIfPresent(ShelfColor.self, forKey: .shelfColor) ?? .neutral
        shelfWasPinned = try values.decodeIfPresent(Bool.self, forKey: .shelfWasPinned) ?? false
    }
}

public struct ShelfRestoreResult: Equatable, Sendable {
    public let item: ShelfItem
    public let shelfID: UUID

    public init(item: ShelfItem, shelfID: UUID) {
        self.item = item
        self.shelfID = shelfID
    }
}
