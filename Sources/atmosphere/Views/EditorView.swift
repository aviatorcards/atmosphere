import SwiftMark
import SwiftUI

struct EditorView: View {
    @Binding var entry: JournalEntry?
    @EnvironmentObject var store: JournalStore
    @Environment(\.colorScheme) var colorScheme
    @State private var editedContent: String = ""
    @State private var editedTitle: String = ""
    @State private var selectedRange: NSRange?
    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    @FocusState private var focusedField: FocusedField?
    private let processor = MarkdownProcessor()
    
    enum FocusedField {
        case title
        case body
    }

    var body: some View {
        Group {
            if let currentEntry = entry {
                #if os(macOS)
                    VStack(spacing: 0) {
                        // Explicit Title Field
                        if isEditing {
                            TextField("Entry Title", text: $editedTitle)
                                .focused($focusedField, equals: .title)
                                .font(.system(size: 28, weight: .bold))
                                .textFieldStyle(.plain)
                                .padding(.horizontal, 22)  // Match editor inset roughly
                                .padding(.top, 24)
                                .padding(.bottom, 8)
                                .onSubmit {
                                    // Move to body on Return
                                    focusedField = .body
                                }
                        } else if let title = currentEntry.title, !title.isEmpty {
                            Text(title)
                                .font(.system(size: 28, weight: .bold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 22)
                                .padding(.top, 24)
                                .padding(.bottom, 8)
                                .textSelection(.enabled)
                        }

                        Divider()
                            .padding(.horizontal, 22)
                            .padding(.bottom, 8)

                        RichTextEditor(
                            text: $editedContent,
                            selectedRange: $selectedRange,
                            isEditable: isEditing,
                            processor: processor
                        )
                        .background(
                            Color(
                                nsColor: NSColor(name: nil) { appearance in
                                    if appearance.bestMatch(from: [.aqua, .darkAqua]) == .aqua {
                                        return NSColor(white: 0.96, alpha: 1.0)
                                    } else {
                                        return NSColor(white: 0.12, alpha: 1.0)
                                    }
                                })
                        )
                    }
                    .onChange(of: isEditing) {
                        if isEditing {
                            // Default to Title when editing starts
                            focusedField = .title
                        } else {
                            focusedField = nil
                        }
                    }
                    .onChange(of: editedContent) {
                        saveEntry()
                    }
                    .onChange(of: editedTitle) {
                        saveEntry()
                    }
                    .onAppear {
                        editedContent = currentEntry.content
                        editedTitle = currentEntry.title ?? ""
                        // Auto-edit if new/empty
                        if currentEntry.content.isEmpty {
                            isEditing = true
                            focusedField = .title
                        }
                    }
                    .onChange(of: entry?.id) {
                        // Reset state when switching entries
                        isEditing = false
                        focusedField = nil

                        if let currentEntry = entry {
                            editedContent = currentEntry.content
                            editedTitle = currentEntry.title ?? ""

                            // Auto-edit if new/empty
                            if currentEntry.content.isEmpty {
                                isEditing = true
                                focusedField = .title
                            }
                        }
                    }
                #else
                    // Fallback for iOS - keep simple TextEditor for now
                    TextEditor(text: $editedContent)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .onChange(of: editedContent) {
                            saveEntry()
                        }
                        .onAppear {
                            editedContent = currentEntry.content
                        }
                        .onChange(of: entry?.id) {
                            if let currentEntry = entry {
                                editedContent = currentEntry.content
                            }
                        }
                #endif
            } else {
                VStack(spacing: 16) {
                    if let url = Bundle.module.url(forResource: "LogoDark", withExtension: "png"),
                        let nsImage = NSImage(contentsOf: url)
                    {
                        let baseImage = Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 128, height: 128)
                            .opacity(0.8)

                        // Use the dark logo (white on black) as the source of truth
                        if colorScheme == .dark {
                            baseImage.blendMode(.screen)
                        } else {
                            // Invert to get black on white, then multiply to drop the white
                            baseImage
                                .colorInvert()
                                .blendMode(.multiply)
                        }
                    } else {
                        // Fallback if logo fails to load
                        Image(systemName: "cloud.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [.blue, .cyan], startPoint: .topLeading,
                                    endPoint: .bottomTrailing)
                            )
                            .opacity(0.8)
                    }
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
                        // Edit Toggle
                        Button(action: {
                            if isEditing {
                                // Done editing - save is handled by onChange but good to reinforce
                                saveEntry()
                                isEditing = false
                            } else {
                                isEditing = true
                            }
                        }) {
                            Label(
                                isEditing ? "Done" : "Edit",
                                systemImage: isEditing ? "checkmark" : "pencil")
                        }
                        .keyboardShortcut(
                            isEditing ? .return : "e", modifiers: isEditing ? .command : .command
                        )
                        .help(isEditing ? "Save and finish editing" : "Edit entry")

                        Spacer()

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
                        .disabled(true)  // Will implement in Phase 4

                        ShareLink(item: entry?.content ?? "")

                        Spacer()

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

    private func saveEntry() {
        guard var currentEntry = entry else { return }
        currentEntry.content = editedContent
        currentEntry.title = editedTitle.isEmpty ? nil : editedTitle
        store.updateEntry(currentEntry)
        // Update binding
        entry = currentEntry
    }
}
