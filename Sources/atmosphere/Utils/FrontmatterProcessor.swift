import Foundation
// import Yams // Let's see if this works if I uncomment it later

struct FrontmatterProcessor {
    static func extract(from content: String) -> (frontmatter: String?, body: String) {
        let scanner = Scanner(string: content)
        guard scanner.scanString("---") != nil else {
            return (nil, content)
        }
        
        // Find the next ---
        let contentNS = content as NSString
        let searchRange = NSRange(location: 3, length: contentNS.length - 3)
        let endRange = contentNS.range(of: "---", options: [], range: searchRange)
        
        if endRange.location != NSNotFound {
            let frontmatterRange = NSRange(location: 3, length: endRange.location - 3)
            let frontmatter = contentNS.substring(with: frontmatterRange).trimmingCharacters(in: .whitespacesAndNewlines)
            let body = contentNS.substring(from: NSMaxRange(endRange)).trimmingCharacters(in: .whitespacesAndNewlines)
            return (frontmatter, body)
        }
        
        return (nil, content)
    }
}
