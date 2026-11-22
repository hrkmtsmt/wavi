import AppKit
import Observation

/// Which panel is open. Only one at a time.
enum OpenPanel {
    case help
    case settings
}

/// What a drag over the window would open, shown as a preview tab.
struct DragPreview: Equatable {
    var name: String
    var size: String
    /// True when the current tab is blank and will be replaced.
    var replacesSelection: Bool
    var urls: [URL]
}

/// The state of the single DocumentWindow: its tabs, the open panel and drag state.
@Observable
final class DocumentStore {
    private(set) var documents: [TextDocument]
    var selectedID: TextDocument.ID
    var openPanel: OpenPanel?
    private(set) var dragPreview: DragPreview?
    private(set) var isCopied = false

    @ObservationIgnored var presentMessage: (String) -> Void = { _ in }
    @ObservationIgnored var strings: () -> Strings = { Strings(language: .system) }
    @ObservationIgnored private var copiedTask: Task<Void, Never>?
    /// Opens run one after another so tabs keep the order files were given in.
    @ObservationIgnored private var openQueue: Task<Void, Never>?

    init() {
        let blank = TextDocument()
        documents = [blank]
        selectedID = blank.id
    }

    var selected: TextDocument {
        documents.first { $0.id == selectedID } ?? documents[0]
    }

    // MARK: - Tabs

    func newTab() {
        let document = TextDocument()
        documents.append(document)
        selectedID = document.id
    }

    func select(_ document: TextDocument) {
        selectedID = document.id
    }

    func selectNeighbor(offset: Int) {
        guard let index = documents.firstIndex(where: { $0.id == selectedID }) else { return }
        let next = (index + offset + documents.count) % documents.count
        selectedID = documents[next].id
    }

    /// Removes a tab without asking. The window asks about unsaved changes first.
    func remove(_ document: TextDocument) {
        guard let index = documents.firstIndex(where: { $0.id == document.id }) else { return }
        documents.remove(at: index)
        if documents.isEmpty {
            let blank = TextDocument()
            documents = [blank]
            selectedID = blank.id
        } else if selectedID == document.id {
            selectedID = documents[min(index, documents.count - 1)].id
        }
    }

    // MARK: - Opening

    /// Opens files. The first one replaces the current tab if it is blank; the rest open in new tabs. A file that is already open is selected instead.
    func open(_ urls: [URL]) {
        let previous = openQueue
        openQueue = Task {
            await previous?.value
            for url in urls {
                await open(url)
            }
        }
    }

    private func open(_ url: URL) async {
        let url = url.standardizedFileURL
        if let existing = documents.first(where: { $0.url?.standardizedFileURL == url }) {
            selectedID = existing.id
            return
        }
        let name = url.lastPathComponent
        let result = await Task.detached(priority: .userInitiated) { () -> Result<(DecodedText, Bool), Error> in
            Result {
                let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
                if size > TextDecoder.openLimit { throw TextFileError.tooLarge }
                let data = try Data(contentsOf: url, options: .mappedIfSafe)
                return (try TextDecoder.decode(data), size > TextDecoder.readOnlyThreshold)
            }
        }.value

        switch result {
        case .success(let (decoded, readOnly)):
            insert(TextDocument(url: url, decoded: decoded, isReadOnly: readOnly))
            NSDocumentController.shared.noteNewRecentDocumentURL(url)
        case .failure(TextFileError.binary):
            presentMessage(strings().notText(name))
        case .failure(TextFileError.tooLarge):
            presentMessage(strings().tooLarge(name))
        case .failure:
            presentMessage(strings().cannotRead(name))
        }
    }

    private func insert(_ document: TextDocument) {
        if let index = documents.firstIndex(where: { $0.id == selectedID }), documents[index].isBlank {
            documents[index] = document
        } else {
            documents.append(document)
        }
        selectedID = document.id
    }

    // MARK: - Drag and drop

    func beginDrag(_ urls: [URL]) {
        guard let first = urls.first else { return }
        let size = (try? first.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        dragPreview = DragPreview(
            name: first.lastPathComponent,
            size: ByteFormat.string(size),
            replacesSelection: selected.isBlank,
            urls: urls
        )
    }

    func endDrag() {
        dragPreview = nil
    }

    // MARK: - Copy

    /// Copies the whole text of the current tab, exactly as it is.
    func copyAll() {
        let text = selected.text
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        isCopied = true
        copiedTask?.cancel()
        copiedTask = Task { [weak self] in
            try? await Task.sleep(for: Timing.doneDuration)
            guard !Task.isCancelled else { return }
            self?.isCopied = false
        }
    }

    func resetCopied() {
        copiedTask?.cancel()
        isCopied = false
    }

    // MARK: - Panels

    func toggle(_ panel: OpenPanel) {
        openPanel = openPanel == panel ? nil : panel
    }
}
