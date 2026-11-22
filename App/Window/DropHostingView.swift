import AppKit
import SwiftUI

/// A view that takes file drags for the whole window. Views below it that also accept drags (the text view) hand file drags up to it.
protocol FileDropTarget: AnyObject {}

/// Hosts the SwiftUI screen and accepts file drops anywhere in the window.
final class DropHostingView<Content: View>: NSHostingView<Content>, FileDropTarget {
    var onDragEntered: ([URL]) -> Void = { _ in }
    var onDragExited: () -> Void = {}
    var onDrop: ([URL]) -> Void = { _ in }

    required init(rootView: Content) {
        super.init(rootView: rootView)
        registerForDraggedTypes([.fileURL])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    private func fileURLs(_ info: NSDraggingInfo) -> [URL] {
        let options: [NSPasteboard.ReadingOptionKey: Any] = [.urlReadingFileURLsOnly: true]
        let urls = info.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: options) as? [URL] ?? []
        return urls.filter { url in
            var isDirectory: ObjCBool = false
            return FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) && !isDirectory.boolValue
        }
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let urls = fileURLs(sender)
        guard !urls.isEmpty else { return [] }
        onDragEntered(urls)
        return .copy
    }

    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        fileURLs(sender).isEmpty ? [] : .copy
    }

    override func draggingExited(_ sender: NSDraggingInfo?) {
        onDragExited()
    }

    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        !fileURLs(sender).isEmpty
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let urls = fileURLs(sender)
        onDragExited()
        guard !urls.isEmpty else { return false }
        onDrop(urls)
        return true
    }

    override func draggingEnded(_ sender: NSDraggingInfo) {
        onDragExited()
    }
}
