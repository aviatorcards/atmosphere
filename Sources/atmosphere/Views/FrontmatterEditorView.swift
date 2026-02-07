import SwiftUI

struct FrontmatterEditorView: View {
    @Binding var frontmatter: [String: CodableValue]?
    @State private var isExpanded: Bool = false
    @State private var newKey: String = ""
    @State private var newValue: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                    Text("Frontmatter")
                        .font(.headline)
                    if let count = frontmatter?.count, count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.secondary.opacity(0.2)))
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                VStack(alignment: .leading, spacing: 4) {
                    if let fm = frontmatter, !fm.isEmpty {
                        ForEach(fm.keys.sorted(), id: \.self) { key in
                            HStack {
                                Text(key)
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .frame(width: 80, alignment: .leading)
                                
                                FrontmatterValueField(value: Binding(
                                    get: { frontmatter?[key] ?? .string("") },
                                    set: { frontmatter?[key] = $0 }
                                ))
                                
                                Button(action: { frontmatter?.removeValue(forKey: key) }) {
                                    Image(systemName: "minus.circle")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    } else {
                        Text("No frontmatter fields")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Add new field
                    HStack {
                        TextField("Key", text: $newKey)
                            .textFieldStyle(.roundedBorder)
                        TextField("Value", text: $newValue)
                            .textFieldStyle(.roundedBorder)
                        Button(action: addField) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                        }
                        .buttonStyle(.plain)
                        .disabled(newKey.isEmpty)
                    }
                    .padding(.top, 4)
                }
                .padding(.leading, 20)
                .transition(.opacity)
            }
        }
        .padding(.vertical, 8)
    }

    private func addField() {
        if frontmatter == nil { frontmatter = [:] }
        frontmatter?[newKey] = .string(newValue)
        newKey = ""
        newValue = ""
    }
}

struct FrontmatterValueField: View {
    @Binding var value: CodableValue

    var body: some View {
        switch value {
        case .string(let s):
            TextField("", text: Binding(
                get: { s },
                set: { value = .string($0) }
            ))
            .textFieldStyle(.roundedBorder)
        case .int(let i):
            TextField("", text: Binding(
                get: { String(i) },
                set: { if let val = Int($0) { value = .int(val) } }
            ))
            .textFieldStyle(.roundedBorder)
        case .double(let d):
            TextField("", text: Binding(
                get: { String(d) },
                set: { if let val = Double($0) { value = .double(val) } }
            ))
            .textFieldStyle(.roundedBorder)
        case .bool(let b):
            Toggle("", isOn: Binding(
                get: { b },
                set: { value = .bool($0) }
            ))
            .labelsHidden()
        case .array:
            Text("Array (editing not supported)")
                .font(.caption)
        case .dictionary:
            Text("Dictionary (editing not supported)")
                .font(.caption)
        }
    }
}
