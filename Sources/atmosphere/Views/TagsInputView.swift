import SwiftUI

struct TagsInputView: View {
    @Binding var tags: [String]
    @Binding var focusTrigger: Bool
    
    @State private var newTagText: String = ""
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Existing tags list
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(tags, id: \.self) { tag in
                        HStack(spacing: 4) {
                            Text(tag)
                                .font(.caption)
                            Button {
                                removeTag(tag)
                            } label: {
                                Image(systemName: "xmark")
                                    .font(.system(size: 8))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
                        .background(Capsule().fill(Color.secondary.opacity(0.15)))
                        .overlay(Capsule().stroke(Color.secondary.opacity(0.3), lineWidth: 0.5))
                    }
                    
                    // Input field
                    TextField("Add tag...", text: $newTagText)
                        .focused($isFocused)
                        .textFieldStyle(.plain)
                        .font(.caption)
                        .frame(width: 80)
                        .onSubmit {
                            addTag()
                        }
                        .onChange(of: newTagText) {
                            if newTagText.hasSuffix(",") {
                                newTagText = String(newTagText.dropLast())
                                addTag()
                            }
                        }
                }
            }
        }
        .onChange(of: focusTrigger) {
            isFocused = true
        }
    }
    
    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty && !tags.contains(trimmed) {
            withAnimation {
                tags.append(trimmed)
            }
        }
        newTagText = ""
        // keep focus?
        isFocused = true
    }
    
    private func removeTag(_ tag: String) {
        withAnimation {
            tags.removeAll { $0 == tag }
        }
    }
}
