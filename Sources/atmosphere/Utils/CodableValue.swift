import Foundation

/// A type-safe wrapper for arbitrary Codable values, useful for frontmatter and other dynamic data.
enum CodableValue: Codable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case array([CodableValue])
    case dictionary([String: CodableValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            self = .string(value)
        } else if let value = try? container.decode(Int.self) {
            self = .int(value)
        } else if let value = try? container.decode(Double.self) {
            self = .double(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .bool(value)
        } else if let value = try? container.decode([CodableValue].self) {
            self = .array(value)
        } else if let value = try? container.decode([String: CodableValue].self) {
            self = .dictionary(value)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container, debugDescription: "Unsupported CodableValue type")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .array(let value): try container.encode(value)
        case .dictionary(let value): try container.encode(value)
        }
    }

    // Helper to convert from Any
    static func fromAny(_ value: Any) -> CodableValue? {
        if let s = value as? String { return .string(s) }
        if let i = value as? Int { return .int(i) }
        if let d = value as? Double { return .double(d) }
        if let b = value as? Bool { return .bool(b) }
        if let a = value as? [Any] {
            return .array(a.compactMap { fromAny($0) })
        }
        if let d = value as? [String: Any] {
            var dict: [String: CodableValue] = [:]
            for (k, v) in d {
                if let cv = fromAny(v) {
                    dict[k] = cv
                }
            }
            return .dictionary(dict)
        }
        return nil
    }

    // Helper to convert to Any
    var anyValue: Any {
        switch self {
        case .string(let s): return s
        case .int(let i): return i
        case .double(let d): return d
        case .bool(let b): return b
        case .array(let a): return a.map { $0.anyValue }
        case .dictionary(let d): return d.mapValues { $0.anyValue }
        }
    }
}
