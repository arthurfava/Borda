import Foundation

public struct ShelfItem: Codable, Equatable, Identifiable, Sendable {
    public enum Kind: String, Codable, Sendable {
        case file
        case folder
        case text
        case richText
        case image
        case url
    }

    public let id: UUID
    public let kind: Kind
    public let displayName: String
    public let storedFileName: String
    public let createdAt: Date
    public let byteCount: Int64

    public init(
        id: UUID = UUID(),
        kind: Kind,
        displayName: String,
        storedFileName: String,
        createdAt: Date = Date(),
        byteCount: Int64
    ) {
        self.id = id
        self.kind = kind
        self.displayName = displayName
        self.storedFileName = storedFileName
        self.createdAt = Date(
            timeIntervalSince1970: (createdAt.timeIntervalSince1970 * 1_000).rounded(.down) / 1_000
        )
        self.byteCount = byteCount
    }
}
