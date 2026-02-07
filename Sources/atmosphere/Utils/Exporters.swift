import Foundation

protocol EntryExporter {
    func export(entry: JournalEntry, to url: URL) throws
}

class MarkdownExporter: EntryExporter {
    func export(entry: JournalEntry, to url: URL) throws {
        var content = ""
        
        // Generate Frontmatter
        var fm: [String: Any] = [:]
        if let entryFM = entry.frontmatter {
            for (k, v) in entryFM {
                fm[k] = v.anyValue
            }
        }
        
        // Always include basic fields in frontmatter for portability
        fm["title"] = entry.title
        fm["date"] = ISO8601DateFormatter().string(from: entry.date)
        if !entry.tags.isEmpty {
            fm["tags"] = entry.tags
        }
        if let loc = entry.locationName {
            fm["location"] = loc
        }
        
        // Simple YAML generation
        content += "---\n"
        for (key, value) in fm.sorted(by: { $0.key < $1.key }) {
            if let val = value as? String {
                let escaped = val.replacingOccurrences(of: "\"", with: "\\\"")
                content += "\(key): \"\(escaped)\"\n"
            } else if let val = value as? [String] {
                let tags = val.map { "\"\($0)\"" }.joined(separator: ", ")
                content += "\(key): [\(tags)]\n"
            } else {
                content += "\(key): \(value)\n"
            }
        }
        content += "---\n\n"
        
        content += entry.content
        
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
}

class JSONExporter: EntryExporter {
    func export(entry: JournalEntry, to url: URL) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(entry)
        try data.write(to: url, options: .atomic)
    }
}