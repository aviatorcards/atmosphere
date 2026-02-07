import Foundation

#if os(macOS)
    import AppKit
#endif

class RegexHighlighter {
    private let textStorage: NSMutableAttributedString

    // Fonts & Colors
    #if os(macOS)
        private let baseFont = NSFont.systemFont(ofSize: 16)
        private let headingColors: [NSColor] = [.labelColor, .labelColor, .labelColor]
        private let codeFont = NSFont.monospacedSystemFont(ofSize: 15, weight: .regular)
        private let secondaryColor = NSColor.secondaryLabelColor
        private let accentColor = NSColor.controlAccentColor
    #endif

    init(textStorage: NSMutableAttributedString) {
        self.textStorage = textStorage
    }

    func highlight() {
        let string = textStorage.string
        let range = NSRange(location: 0, length: string.utf16.count)

        // Reset base attributes
        textStorage.removeAttribute(.font, range: range)
        textStorage.removeAttribute(.foregroundColor, range: range)
        textStorage.addAttribute(.font, value: baseFont, range: range)
        textStorage.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)

        // Frontmatter: --- ... ---
        highlightRegex(pattern: "(?s)^---\\s*$.*?^---\\s*$", options: [.anchorsMatchLines]) { matchRange in
            textStorage.addAttribute(.foregroundColor, value: secondaryColor, range: matchRange)
            // Use a slightly smaller font for frontmatter
            if let smallerFont = NSFont.systemFont(ofSize: 14) as NSFont? {
                textStorage.addAttribute(.font, value: smallerFont, range: matchRange)
            }
        }

        // Shortcodes: {{< name ... >}}
        highlightRegex(pattern: "\\{\\{<.*?\\>\\}\\}") { matchRange in
            textStorage.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: matchRange)
        }

        // Headers: # Header
        highlightRegex(pattern: "^#{1,6}\\s+.*$", options: [.anchorsMatchLines]) { matchRange in
            // Determine level
            let substring = (string as NSString).substring(with: matchRange)
            let level = substring.prefix(while: { $0 == "#" }).count

            let size: CGFloat = level == 1 ? 32 : (level == 2 ? 26 : 22)
            let weight: NSFont.Weight = level == 1 ? .bold : .semibold

            if let font = NSFont.systemFont(ofSize: size, weight: weight) as NSFont? {
                textStorage.addAttribute(.font, value: font, range: matchRange)
            }
        }

        // Bold: **text**
        highlightRegex(pattern: "(\\*\\*|__)(.+?)(\\1)") { matchRange in
            let currentFont =
                textStorage.attribute(.font, at: matchRange.location, effectiveRange: nil)
                as? NSFont ?? baseFont
            if let boldFont = NSFontManager.shared.convert(currentFont, toHaveTrait: .boldFontMask)
                as NSFont?
            {
                textStorage.addAttribute(.font, value: boldFont, range: matchRange)
            }
        }

        // Italic: *text* (avoiding match within **)
        highlightRegex(pattern: "(\\*|_)(?![\\*_])(.+?)(?<![\\*_])(\\1)") { matchRange in
            let currentFont =
                textStorage.attribute(.font, at: matchRange.location, effectiveRange: nil)
                as? NSFont ?? baseFont
            if let italicFont = NSFontManager.shared.convert(
                currentFont, toHaveTrait: .italicFontMask) as NSFont?
            {
                textStorage.addAttribute(.font, value: italicFont, range: matchRange)
            }
        }

        // Code: `text`
        highlightRegex(pattern: "`[^`]+`") { matchRange in
            textStorage.addAttribute(.font, value: codeFont, range: matchRange)
            textStorage.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: matchRange)
            textStorage.addAttribute(
                .backgroundColor, value: NSColor.quaternaryLabelColor, range: matchRange)
        }

        // Blockquote: > text
        highlightRegex(pattern: "^>\\s+.*$", options: [.anchorsMatchLines]) { matchRange in
            textStorage.addAttribute(.foregroundColor, value: secondaryColor, range: matchRange)
        }

        // Lists: - item or * item
        highlightRegex(pattern: "^[\\*\\-]\\s+", options: [.anchorsMatchLines]) { matchRange in
            textStorage.addAttribute(.foregroundColor, value: accentColor, range: matchRange)
        }
    }

    private func highlightRegex(
        pattern: String, options: NSRegularExpression.Options = [], handler: (NSRange) -> Void
    ) {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return
        }
        let string = textStorage.string
        let range = NSRange(location: 0, length: string.utf16.count)

        regex.enumerateMatches(in: string, options: [], range: range) { match, _, _ in
            if let matchRange = match?.range {
                handler(matchRange)
            }
        }
    }
}
