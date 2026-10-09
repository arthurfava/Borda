import Foundation

public struct BordaPreferences: Codable, Equatable, Sendable {
    public var leftEdgeEnabled = true
    public var rightEdgeEnabled = true
    public var triggerWidth: Double = 8
    public var openingDelay: Double = 0.08
    public var collapseDelay: Double = 0.55
    public var removeAfterSuccessfulDrag = true
    public var clipboardHistoryEnabled = false
    public var clipboardHistoryLimit = 20
    public var watchedFolderPaths: [String] = []
    public var watchedFolderBookmarks: [String: Data] = [:]
    public var launchAtLogin = true
    public var showShortcutKeyCode: UInt32 = 11 // B
    public var captureShortcutKeyCode: UInt32 = 8 // C
    public var shortcutModifiers: UInt32 = 0 // command + option

    public init() {}

    private enum CodingKeys: String, CodingKey {
        case leftEdgeEnabled, rightEdgeEnabled, triggerWidth, openingDelay, collapseDelay
        case removeAfterSuccessfulDrag, clipboardHistoryEnabled, clipboardHistoryLimit
        case watchedFolderPaths, watchedFolderBookmarks, launchAtLogin, showShortcutKeyCode, captureShortcutKeyCode, shortcutModifiers
    }

    public init(from decoder: Decoder) throws {
        self.init()
        let values = try decoder.container(keyedBy: CodingKeys.self)
        leftEdgeEnabled = try values.decodeIfPresent(Bool.self, forKey: .leftEdgeEnabled) ?? leftEdgeEnabled
        rightEdgeEnabled = try values.decodeIfPresent(Bool.self, forKey: .rightEdgeEnabled) ?? rightEdgeEnabled
        triggerWidth = try values.decodeIfPresent(Double.self, forKey: .triggerWidth) ?? triggerWidth
        openingDelay = try values.decodeIfPresent(Double.self, forKey: .openingDelay) ?? openingDelay
        collapseDelay = try values.decodeIfPresent(Double.self, forKey: .collapseDelay) ?? collapseDelay
        removeAfterSuccessfulDrag = try values.decodeIfPresent(Bool.self, forKey: .removeAfterSuccessfulDrag) ?? removeAfterSuccessfulDrag
        clipboardHistoryEnabled = try values.decodeIfPresent(Bool.self, forKey: .clipboardHistoryEnabled) ?? clipboardHistoryEnabled
        clipboardHistoryLimit = try values.decodeIfPresent(Int.self, forKey: .clipboardHistoryLimit) ?? clipboardHistoryLimit
        watchedFolderPaths = try values.decodeIfPresent([String].self, forKey: .watchedFolderPaths) ?? watchedFolderPaths
        watchedFolderBookmarks = try values.decodeIfPresent([String: Data].self, forKey: .watchedFolderBookmarks) ?? watchedFolderBookmarks
        launchAtLogin = try values.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? launchAtLogin
        showShortcutKeyCode = try values.decodeIfPresent(UInt32.self, forKey: .showShortcutKeyCode) ?? showShortcutKeyCode
        captureShortcutKeyCode = try values.decodeIfPresent(UInt32.self, forKey: .captureShortcutKeyCode) ?? captureShortcutKeyCode
        shortcutModifiers = try values.decodeIfPresent(UInt32.self, forKey: .shortcutModifiers) ?? shortcutModifiers
        normalize()
    }

    mutating func normalize() {
        triggerWidth = min(max(triggerWidth, 4), 24)
        openingDelay = min(max(openingDelay, 0), 1.5)
        collapseDelay = min(max(collapseDelay, 0.15), 3)
        clipboardHistoryLimit = min(max(clipboardHistoryLimit, 1), 100)
        watchedFolderPaths = Array(Set(watchedFolderPaths
            .map { URL(fileURLWithPath: $0).standardizedFileURL.path }
            .filter { !$0.isEmpty })).sorted()
        watchedFolderBookmarks = watchedFolderBookmarks.filter { watchedFolderPaths.contains($0.key) }
    }
}

public final class BordaPreferencesStore {
    public private(set) var value: BordaPreferences
    private let fileURL: URL

    public init(rootURL: URL) throws {
        try FileManager.default.createDirectory(at: rootURL, withIntermediateDirectories: true)
        fileURL = rootURL.appendingPathComponent("Preferences.json")
        if FileManager.default.fileExists(atPath: fileURL.path) {
            value = try JSONDecoder().decode(BordaPreferences.self, from: Data(contentsOf: fileURL))
            value.normalize()
        } else {
            value = BordaPreferences()
            try persist()
        }
    }

    public func update(_ changes: (inout BordaPreferences) -> Void) throws {
        changes(&value)
        value.normalize()
        try persist()
    }

    private func persist() throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        try encoder.encode(value).write(to: fileURL, options: .atomic)
    }
}
