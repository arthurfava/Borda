import AppKit
import Foundation
@preconcurrency import Vision

public final class ShelfActionService {
    public enum ActionError: LocalizedError {
        case noItems
        case commandFailed(String)
        case invalidImage(URL)
        case imageEncodingFailed

        public var errorDescription: String? {
            switch self {
            case .noItems: return CoreL10n.text("error.no_items", "There are no items to process.")
            case .commandFailed(let detail): return CoreL10n.format("error.command_failed", "The action couldn’t be completed: %@", detail)
            case .invalidImage(let url): return CoreL10n.format("error.invalid_image", "%@ isn’t a valid image.", url.lastPathComponent)
            case .imageEncodingFailed: return CoreL10n.text("error.image_encoding", "The processed image couldn’t be saved.")
            }
        }
    }

    public init() {}

    public func createZIP(from sourceURLs: [URL], in destinationDirectory: URL,
                          preferredName: String = "Borda Items") throws -> URL {
        guard !sourceURLs.isEmpty else { throw ActionError.noItems }
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let staging = FileManager.default.temporaryDirectory
            .appendingPathComponent("BordaZIP-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: staging) }

        for source in sourceURLs {
            var target = staging.appendingPathComponent(source.lastPathComponent)
            var suffix = 2
            while FileManager.default.fileExists(atPath: target.path) {
                let stem = source.deletingPathExtension().lastPathComponent
                let ext = source.pathExtension
                let candidate = ext.isEmpty ? "\(stem) \(suffix)" : "\(stem) \(suffix).\(ext)"
                target = staging.appendingPathComponent(candidate)
                suffix += 1
            }
            try FileManager.default.copyItem(at: source, to: target)
        }

        let archive = uniqueURL(in: destinationDirectory, name: sanitized(preferredName), extension: "zip")
        try run("/usr/bin/ditto", arguments: ["-c", "-k", "--sequesterRsrc", staging.path, archive.path])
        return archive
    }

    public func resizeImage(at sourceURL: URL, maximumDimension: CGFloat,
                            in destinationDirectory: URL) throws -> URL {
        guard maximumDimension > 0,
              let source = NSImage(contentsOf: sourceURL),
              let cgImage = source.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ActionError.invalidImage(sourceURL)
        }
        let width = CGFloat(cgImage.width)
        let height = CGFloat(cgImage.height)
        let ratio = min(1, maximumDimension / max(width, height))
        let targetWidth = max(1, Int((width * ratio).rounded()))
        let targetHeight = max(1, Int((height * ratio).rounded()))
        guard let context = CGContext(data: nil, width: targetWidth, height: targetHeight,
                                      bitsPerComponent: 8, bytesPerRow: 0,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            throw ActionError.imageEncodingFailed
        }
        context.interpolationQuality = .high
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: targetWidth, height: targetHeight))
        guard let outputImage = context.makeImage() else { throw ActionError.imageEncodingFailed }
        let representation = NSBitmapImageRep(cgImage: outputImage)
        let sourceExtension = sourceURL.pathExtension.lowercased()
        let type: NSBitmapImageRep.FileType = ["jpg", "jpeg"].contains(sourceExtension) ? .jpeg : .png
        let properties: [NSBitmapImageRep.PropertyKey: Any] = type == .jpeg ? [.compressionFactor: 0.9] : [:]
        guard let data = representation.representation(using: type, properties: properties) else {
            throw ActionError.imageEncodingFailed
        }
        try FileManager.default.createDirectory(at: destinationDirectory, withIntermediateDirectories: true)
        let ext = type == .jpeg ? "jpg" : "png"
        let name = sourceURL.deletingPathExtension().lastPathComponent + CoreL10n.text("generated.resized_suffix", " resized")
        let target = uniqueURL(in: destinationDirectory, name: name, extension: ext)
        try data.write(to: target, options: .atomic)
        return target
    }

    public func recognizeText(in imageURL: URL) async throws -> String {
        guard let image = NSImage(contentsOf: imageURL),
              let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw ActionError.invalidImage(imageURL)
        }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error { continuation.resume(throwing: error); return }
                let text = (request.results as? [VNRecognizedTextObservation])?
                    .compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n") ?? ""
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            let supported = (try? request.supportedRecognitionLanguages()) ?? ["en-US"]
            let preferred = Locale.preferredLanguages.compactMap { preferred in
                supported.first { supportedLanguage in
                    supportedLanguage.caseInsensitiveCompare(preferred) == .orderedSame ||
                    supportedLanguage.split(separator: "-").first == preferred.split(separator: "-").first
                }
            }
            request.recognitionLanguages = Array((preferred + ["en-US", "pt-BR"] + supported).uniqued().prefix(4))
            DispatchQueue.global(qos: .userInitiated).async {
                do { try VNImageRequestHandler(cgImage: cgImage).perform([request]) }
                catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func run(_ executable: String, arguments: [String]) throws {
        let process = Process()
        let errorPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardError = errorPipe
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let data = errorPipe.fileHandleForReading.readDataToEndOfFile()
            throw ActionError.commandFailed(String(data: data, encoding: .utf8) ?? CoreL10n.text("error.unknown", "unknown error"))
        }
    }

    private func sanitized(_ value: String) -> String {
        let clean = value.replacingOccurrences(of: "/", with: "-")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.isEmpty ? CoreL10n.text("generated.borda_items", "Borda Items") : clean
    }

    private func uniqueURL(in directory: URL, name: String, extension ext: String) -> URL {
        var candidate = directory.appendingPathComponent("\(name).\(ext)")
        var suffix = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = directory.appendingPathComponent("\(name) \(suffix).\(ext)")
            suffix += 1
        }
        return candidate
    }
}

private extension Sequence where Element: Hashable {
    func uniqued() -> [Element] {
        var seen = Set<Element>()
        return filter { seen.insert($0).inserted }
    }
}
