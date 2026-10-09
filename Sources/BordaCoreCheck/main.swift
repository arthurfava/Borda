import Foundation
import BordaCore
import AppKit

enum CheckFailure: LocalizedError {
    case failed(String)
    var errorDescription: String? { if case .failed(let message) = self { return message }; return nil }
}

func expect(_ condition: @autoclosure () throws -> Bool, _ message: String) throws {
    guard try condition() else { throw CheckFailure.failed(message) }
}

func temporaryRoot() -> URL {
    FileManager.default.temporaryDirectory.appendingPathComponent("BordaCheck-\(UUID().uuidString)", isDirectory: true)
}

func checkMigrationAndPersistence() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let vault = root.appendingPathComponent("Vault", isDirectory: true)
    try FileManager.default.createDirectory(at: vault, withIntermediateDirectories: true)
    let legacy = ShelfItem(kind: .text, displayName: "Legado", storedFileName: "Texto.txt", byteCount: 6)
    let itemDirectory = vault.appendingPathComponent(legacy.id.uuidString, isDirectory: true)
    try FileManager.default.createDirectory(at: itemDirectory, withIntermediateDirectories: true)
    try Data("legado".utf8).write(to: itemDirectory.appendingPathComponent("Texto.txt"))
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .millisecondsSince1970
    try encoder.encode([legacy]).write(to: root.appendingPathComponent("Shelf.json"))

    let migrated = try ShelfStore(rootURL: root)
    try expect(migrated.shelves.count == 1, "A migração não criou a primeira caixa.")
    try expect(migrated.items(inShelf: migrated.shelves[0].id) == [legacy], "O item legado não foi preservado na caixa.")
    let reloaded = try ShelfStore(rootURL: root)
    try expect(reloaded.shelves == migrated.shelves, "As caixas não sobreviveram à reinicialização.")
}

func checkMultipleShelvesAndItems() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = try ShelfStore(rootURL: root)
    let left = try store.createShelf(side: .left, screenID: "1", normalizedY: 0.25)
    let right = try store.createShelf(side: .right, screenID: "1", normalizedY: 0.75)
    let first = try store.addText("Primeiro", toShelf: left.id)
    let second = try store.addText("Segundo", toShelf: left.id)
    let third = try store.addText("Terceiro", toShelf: right.id)
    try expect(store.shelves.count == 2, "A segunda caixa não foi criada.")
    try expect(store.items(inShelf: left.id) == [first, second], "A mesma caixa não aceitou vários itens.")
    try expect(store.items(inShelf: right.id) == [third], "O item entrou na caixa errada.")
}

func checkFileCopy() throws {
    let root = temporaryRoot()
    let sourceRoot = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root); try? FileManager.default.removeItem(at: sourceRoot) }
    try FileManager.default.createDirectory(at: sourceRoot, withIntermediateDirectories: true)
    let source = sourceRoot.appendingPathComponent("original.txt")
    try Data("conteúdo".utf8).write(to: source)
    let store = try ShelfStore(rootURL: root)
    let shelf = try store.createShelf(side: .right, screenID: nil, normalizedY: 0.5)
    let item = try store.addFile(at: source, toShelf: shelf.id)
    try expect(FileManager.default.fileExists(atPath: source.path), "O arquivo original foi removido.")
    try expect(try String(contentsOf: store.payloadURL(for: item), encoding: .utf8) == "conteúdo", "A cópia diverge do original.")
}

func checkRemovalPrunesEmptyShelf() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = try ShelfStore(rootURL: root)
    let shelf = try store.createShelf(side: .right, screenID: nil, normalizedY: 0.5)
    let item = try store.addText("temporário", toShelf: shelf.id)
    let payload = store.payloadURL(for: item)
    try store.remove(item, fromShelf: shelf.id)
    try expect(store.shelves.isEmpty, "A caixa vazia permaneceu ativa.")
    try expect(!FileManager.default.fileExists(atPath: payload.path), "O payload removido permaneceu no cofre.")
}

func checkExportAndRestoreSourceShelf() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = try ShelfStore(rootURL: root)
    let shelf = try store.createShelf(side: .left, screenID: "42", normalizedY: 0.22)
    let item = try store.addText("voltar depois", toShelf: shelf.id)
    let payload = store.payloadURL(for: item)
    try store.markExported(item, fromShelf: shelf.id)
    try expect(store.shelves.isEmpty, "A caixa vazia não sumiu após a retirada.")
    try expect(store.canRestoreExportedItem, "O histórico não registrou o item retirado.")
    try expect(FileManager.default.fileExists(atPath: payload.path), "O payload retirado foi apagado.")

    let reloaded = try ShelfStore(rootURL: root)
    let restored = try reloaded.restoreLastExported()
    try expect(restored?.item == item, "A restauração retornou um item diferente.")
    try expect(restored?.shelfID == shelf.id, "A restauração perdeu a caixa de origem.")
    try expect(reloaded.shelves.first?.side == .left, "A restauração perdeu a lateral de origem.")
    try expect(reloaded.shelves.first?.screenID == "42", "A restauração perdeu o monitor de origem.")
    try expect(reloaded.shelves.first?.normalizedY == 0.22, "A restauração perdeu a posição de origem.")
}

func checkCorruptMetadataIsNotOverwritten() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let metadata = root.appendingPathComponent("Shelf.json")
    let corrupt = Data("{conteudo-invalido".utf8)
    try corrupt.write(to: metadata)
    do {
        _ = try ShelfStore(rootURL: root)
        throw CheckFailure.failed("Metadados corrompidos foram aceitos silenciosamente.")
    } catch is DecodingError {
        try expect(try Data(contentsOf: metadata) == corrupt, "O JSON corrompido foi sobrescrito.")
    }
}

func checkShelfOrganization() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let store = try ShelfStore(rootURL: root)
    let shelf = try store.createShelf(side: .right, screenID: "1", normalizedY: 0.4)
    let first = try store.addText("Primeiro", toShelf: shelf.id)
    let second = try store.addText("Segundo", toShelf: shelf.id)
    let third = try store.addText("Terceiro", toShelf: shelf.id)

    try store.updateShelfIdentity(shelf.id, name: "Entrega", color: .violet)
    try store.setShelfPinned(shelf.id, pinned: true)
    try store.reorderItems(inShelf: shelf.id, orderedIDs: [third.id, first.id, second.id])
    try expect(store.shelf(withID: shelf.id)?.name == "Entrega", "O nome da caixa não foi salvo.")
    try expect(store.shelf(withID: shelf.id)?.color == .violet, "A cor da caixa não foi salva.")
    try expect(store.shelf(withID: shelf.id)?.isPinned == true, "A caixa não foi fixada.")
    try expect(store.items(inShelf: shelf.id) == [third, first, second], "A ordem dos itens não foi alterada.")

    try store.closeShelf(shelf.id)
    try expect(store.openShelves.isEmpty, "A caixa fechada continuou entre as abertas.")
    try expect(store.recentShelves.map(\.id) == [shelf.id], "A caixa fechada não entrou nas recentes.")
    try store.reopenShelf(shelf.id)
    try expect(store.openShelves.map(\.id) == [shelf.id], "A caixa recente não foi reaberta.")

    let reloaded = try ShelfStore(rootURL: root)
    try expect(reloaded.shelf(withID: shelf.id)?.name == "Entrega", "A organização não persistiu.")
    try expect(reloaded.items(inShelf: shelf.id) == [third, first, second], "A ordem não persistiu.")
}

func checkPreferencesPersistenceAndLimits() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    let preferences = try BordaPreferencesStore(rootURL: root)
    try expect(preferences.value.launchAtLogin, "O Borda deveria abrir com o Mac por padrão.")
    try expect(preferences.value.leftEdgeEnabled, "A borda esquerda deveria vir ligada.")
    try expect(preferences.value.rightEdgeEnabled, "A borda direita deveria vir ligada.")
    try preferences.update { value in
        value.leftEdgeEnabled = false
        value.triggerWidth = 99
        value.openingDelay = -1
        value.clipboardHistoryEnabled = true
        value.clipboardHistoryLimit = 3
        value.watchedFolderPaths = ["/tmp/Entrada"]
        value.removeAfterSuccessfulDrag = false
        value.launchAtLogin = false
    }
    try expect(preferences.value.triggerWidth == 24, "A largura da borda não foi limitada.")
    try expect(preferences.value.openingDelay == 0, "O atraso negativo foi aceito.")

    let reloaded = try BordaPreferencesStore(rootURL: root)
    try expect(!reloaded.value.leftEdgeEnabled, "A lateral configurada não persistiu.")
    try expect(reloaded.value.clipboardHistoryEnabled, "O histórico opcional não persistiu.")
    try expect(reloaded.value.clipboardHistoryLimit == 3, "O limite do histórico não persistiu.")
    try expect(reloaded.value.watchedFolderPaths == ["/tmp/Entrada"], "As pastas observadas não persistiram.")
    try expect(!reloaded.value.removeAfterSuccessfulDrag, "O comportamento pós-arrasto não persistiu.")
    try expect(!reloaded.value.launchAtLogin, "A opção de iniciar com o Mac não persistiu.")
}

func checkMagneticInteractionGeometry() throws {
    let collapsed = CGRect(x: 100, y: 200, width: 44, height: 68)
    let collapsedRegion = ShelfInteractionGeometry.region(around: collapsed, state: .collapsed)
    try expect(collapsedRegion.contains(CGPoint(x: 86, y: 234)), "A capsula nao ganhou alcance magnetico para dentro da tela.")
    try expect(collapsedRegion.contains(CGPoint(x: 122, y: 190)), "A capsula nao ganhou tolerancia vertical.")
    try expect(!collapsedRegion.contains(CGPoint(x: 60, y: 234)), "A area magnetica da capsula ficou grande demais.")

    let expanded = CGRect(x: 100, y: 120, width: 286, height: 228)
    let expandedRegion = ShelfInteractionGeometry.region(around: expanded, state: .expanded)
    try expect(expandedRegion.contains(CGPoint(x: 94, y: 234)), "O card aberto nao preserva o cursor perto da borda.")
    try expect(!expandedRegion.contains(CGPoint(x: 80, y: 234)), "A tolerancia do card aberto ficou grande demais.")
}

func checkQuickActions() throws {
    let root = temporaryRoot()
    defer { try? FileManager.default.removeItem(at: root) }
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let source = root.appendingPathComponent("briefing.txt")
    try Data("Borda".utf8).write(to: source)
    let service = ShelfActionService()
    let archive = try service.createZIP(from: [source], in: root, preferredName: "Pacote")
    try expect(FileManager.default.fileExists(atPath: archive.path), "O ZIP não foi criado.")
    try expect(archive.pathExtension == "zip", "O arquivo criado não é ZIP.")

    let image = NSImage(size: NSSize(width: 400, height: 200))
    image.lockFocus()
    NSColor.systemBlue.setFill()
    NSRect(x: 0, y: 0, width: 400, height: 200).fill()
    image.unlockFocus()
    let imageURL = root.appendingPathComponent("original.png")
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        throw CheckFailure.failed("Não foi possível montar a imagem de teste.")
    }
    try png.write(to: imageURL)
    let resized = try service.resizeImage(at: imageURL, maximumDimension: 100, in: root)
    guard let resizedImage = NSImage(contentsOf: resized) else {
        throw CheckFailure.failed("A imagem redimensionada não pôde ser aberta.")
    }
    try expect(max(resizedImage.size.width, resizedImage.size.height) <= 100.5, "A imagem não foi limitada.")
}

do {
    try checkMigrationAndPersistence(); print("✓ migração e persistência")
    try checkMultipleShelvesAndItems(); print("✓ várias caixas e vários itens")
    try checkFileCopy(); print("✓ cópia sem alterar o original")
    try checkRemovalPrunesEmptyShelf(); print("✓ remoção e descarte da caixa vazia")
    try checkExportAndRestoreSourceShelf(); print("✓ retirada reversível na caixa de origem")
    try checkCorruptMetadataIsNotOverwritten(); print("✓ proteção contra metadados corrompidos")
    try checkShelfOrganization(); print("✓ organização, fixação e caixas recentes")
    try checkPreferencesPersistenceAndLimits(); print("✓ preferências persistentes e validadas")
    try checkMagneticInteractionGeometry(); print("✓ geometria magnética de interação")
    try checkQuickActions(); print("✓ ações rápidas de ZIP e imagem")
    print("Todos os checks do BordaCore passaram.")
} catch {
    FileHandle.standardError.write(Data("Falha: \(error.localizedDescription)\n".utf8))
    exit(1)
}
