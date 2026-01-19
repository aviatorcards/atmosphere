import SwiftMark
import SwiftUI

struct EditorView: View {
    @Binding var entry: JournalEntry?
    @EnvironmentObject var store: JournalStore
    @State private var renderedHTML: String = ""
    @State private var editedContent: String = ""
    @State private var showDeleteConfirmation = false
    private let processor = MarkdownProcessor()

    var body: some View {
        Group {
            if let currentEntry = entry {
                HSplitView {
                    // Editor
                    VStack {
                        TextEditor(text: $editedContent)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                            .onChange(of: editedContent) {
                                updatePreview(content: editedContent)
                                saveEntry()
                            }
                    }
                    .frame(minWidth: 300)

                    // Preview
                    VStack(alignment: .leading) {
                        Text("Preview")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                            .padding(.top, 8)

                        ScrollView {
                            Text(renderedHTML)
                                .padding()
                                .textSelection(.enabled)
                        }
                    }
                    .frame(minWidth: 300)
                }
                .onAppear {
                    editedContent = currentEntry.content
                    updatePreview(content: currentEntry.content)
                }
                .onChange(of: entry?.id) {
                    if let currentEntry = entry {
                        editedContent = currentEntry.content
                        updatePreview(content: currentEntry.content)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("No Entry Selected")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        #if os(macOS)
            .toolbar {
                if entry != nil {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(action: {}) {
                            Label("Add Photo", systemImage: "photo")
                        }
                        .disabled(true)  // Will implement in Phase 3

                        Button(action: {}) {
                            Label("Take a Picture", systemImage: "camera")
                        }
                        .disabled(true)

                        Button(action: {}) {
                            Label("Add Location", systemImage: "location")
                        }
                        .disabled(true)  // Will implement in Phase 4

                        Button(action: {}) {
                            Label("Record Audio", systemImage: "waveform")
                        }
                        .disabled(true) // Will implement in Phase 4

                        ShareLink(item: entry?.content ?? "")

                        Button(action: { showDeleteConfirmation = true }) {
                            Label("Delete", systemImage: "trash")
                        }
                        .help("Move to Trash")
                    }
                }
            }
            .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Move to Trash", role: .destructive) {
                    if let currentEntry = entry {
                        store.deleteEntry(currentEntry)
                        entry = nil
                    }
                }
            } message: {
                Text("This entry will be moved to Trash. You can restore it later.")
            }
        #endif
    }

    private func updatePreview(content: String) {
        let (_, html) = processor.process(content: content)
        renderedHTML = html
    }

    private func saveEntry() {
        guard var currentEntry = entry else { return }
        currentEntry.content = editedContent
        store.updateEntry(currentEntry)
        // Update binding
        entry = currentEntry
    }
}
