import AppKit
import Foundation
import SwiftMark

/// Custom NSTextStorage that maintains markdown as backing store
/// and displays it as attributed text
class MarkdownTextStorage: NSTextStorage {
    private var backingStore = NSMutableAttributedString()
    private let processor: MarkdownProcessor

    // Lazy initialization ensures backingStore is available and prevents initialization loops
    private lazy var highlighter = RegexHighlighter(textStorage: backingStore)

    init(processor: MarkdownProcessor) {
        self.processor = processor
        super.init()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init?(
        pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType
    ) {
        fatalError("init(pasteboardPropertyList:ofType:) has not been implemented")
    }

    // MARK: - NSAttributedString Primitives

    override var string: String {
        backingStore.string
    }

    override func attributes(at location: Int, effectiveRange range: NSRangePointer?)
        -> [NSAttributedString.Key: Any]
    {
        backingStore.attributes(at: location, effectiveRange: range)
    }

    // MARK: - NSMutableAttributedString Primitives

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
        endEditing()
    }

    override func setAttributes(_ attrs: [NSAttributedString.Key: Any]?, range: NSRange) {
        beginEditing()
        backingStore.setAttributes(attrs, range: range)
        edited(.editedAttributes, range: range, changeInLength: 0)
        endEditing()
    }

    // MARK: - Processing

    override func processEditing() {
        // Highlight syntax on the backing store directly without replacing content
        // This preserves the exact input structure (newlines, spaces).
        if editedMask.contains(.editedCharacters) {
            highlighter.highlight()
        }

        super.processEditing()
    }
}
