import AppKit
import Foundation
import SwiftMark

/// Custom NSTextStorage that maintains markdown as backing store
/// and displays it as attributed text
class MarkdownTextStorage: NSTextStorage {
    private var backingStore = NSMutableAttributedString()
    private let processor: MarkdownProcessor
    private var isHighlighting = false

    // Lazy initialization ensures self is available
    // We pass 'self' so that highlighting changes go through our overridden setAttributes
    // which ensures proper notification bubbling (via edited()).
    private lazy var highlighter = RegexHighlighter(textStorage: self)

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
        // Safe to read from backing store directly as it's the source of truth
        backingStore.attributes(at: location, effectiveRange: range)
    }

    // MARK: - NSMutableAttributedString Primitives

    override func replaceCharacters(in range: NSRange, with str: String) {
        beginEditing()
        backingStore.replaceCharacters(in: range, with: str)
        let changeInLength = str.utf16.count - range.length
        edited(.editedCharacters, range: range, changeInLength: changeInLength)
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
        // Prevent infinite recursion since highlighter modifies attributes,
        // which triggers setAttributes -> edited -> processEditing.
        if isHighlighting {
            super.processEditing()
            return
        }

        // Highlight when characters change
        if editedMask.contains(.editedCharacters) {
            isHighlighting = true
            highlighter.highlight()
            isHighlighting = false
        }

        super.processEditing()
    }
}
