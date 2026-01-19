import SwiftMark
import SwiftUI

#if os(macOS)
    import AppKit

    /// NSViewRepresentable wrapper for NSTextView with markdown support
    struct RichTextEditor: NSViewRepresentable {
        @Binding var text: String
        @Binding var selectedRange: NSRange?
        var isEditable: Bool  // Control editing state
        let processor: MarkdownProcessor

        func makeNSView(context: Context) -> NSScrollView {
            // Set up custom text storage FIRST
            let textStorage = MarkdownTextStorage(processor: processor)

            // Create layout manager and add to text storage
            let layoutManager = NSLayoutManager()
            textStorage.addLayoutManager(layoutManager)

            // Create text container and add to layout manager
            let textContainer = NSTextContainer()
            textContainer.widthTracksTextView = true
            layoutManager.addTextContainer(textContainer)

            // Create text view with the text container
            let textView = NSTextView(frame: .zero, textContainer: textContainer)

            // Configure text view
            textView.delegate = context.coordinator
            textView.isRichText = true
            textView.allowsUndo = true
            textView.isEditable = isEditable  // Set initial state
            textView.font = .systemFont(ofSize: 16)
            textView.textColor = .textColor

            // Custom background color - softer in light mode
            textView.backgroundColor = NSColor(name: nil) { appearance in
                if appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua {
                    return NSColor(white: 0.96, alpha: 1.0)  // Off-white/light gray for light mode
                } else {
                    return NSColor(white: 0.12, alpha: 1.0)  // Dark gray for dark mode (matches standard dark window)
                }
            }

            textView.drawsBackground = true
            textView.isAutomaticQuoteSubstitutionEnabled = false
            textView.isAutomaticDashSubstitutionEnabled = false
            textView.isAutomaticTextReplacementEnabled = false
            textView.textContainerInset = NSSize(width: 20, height: 20)

            // Set initial text and trigger rendering
            textStorage.replaceCharacters(in: NSRange(location: 0, length: 0), with: text)

            // Create scroll view
            let scrollView = NSScrollView()
            scrollView.documentView = textView
            scrollView.hasVerticalScroller = true
            scrollView.hasHorizontalScroller = false
            scrollView.autohidesScrollers = true

            return scrollView
        }

        func updateNSView(_ scrollView: NSScrollView, context: Context) {
            guard let textView = scrollView.documentView as? NSTextView else { return }

            // Update editable state
            if textView.isEditable != isEditable {
                textView.isEditable = isEditable
                // Apply cursor change if needed
                if isEditable {
                    textView.window?.makeFirstResponder(textView)
                }
            }

            // Update text if it changed externally
            let currentText = textView.string
            if currentText != text {
                textView.string = text
            }
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(self)
        }

        class Coordinator: NSObject, NSTextViewDelegate {
            var parent: RichTextEditor

            init(_ parent: RichTextEditor) {
                self.parent = parent
            }

            func textDidChange(_ notification: Notification) {
                guard let textView = notification.object as? NSTextView else { return }
                parent.text = textView.string
            }

            func textViewDidChangeSelection(_ notification: Notification) {
                guard let textView = notification.object as? NSTextView else { return }
                parent.selectedRange = textView.selectedRange()
            }
        }
    }
#endif
