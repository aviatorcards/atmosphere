import AVFoundation
import SwiftMark
import SwiftUI
import UniformTypeIdentifiers

struct EditorView: View {
    @Binding var entry: JournalEntry?
    @EnvironmentObject var store: JournalStore
    @Environment(\.colorScheme) var colorScheme
    @State private var editedContent: String = ""
    @State private var editedTitle: String = ""
    @State private var editedTags: [String] = []
    @State private var tagsFocusTrigger: Bool = false
    @State private var selectedRange: NSRange?
    @State private var showDeleteConfirmation = false
    @State private var isEditing = false
    @State private var isImporterPresented = false
    @State private var editedPhotoPaths: [String] = []
    @State private var editedAudioPaths: [String] = []
    @State private var editedFrontmatter: [String: CodableValue]? = nil
    @State private var expandedImage: URL? = nil
    @StateObject private var locationManager = LocationManager()
    @StateObject private var audioRecorder = AudioRecorder()
    @FocusState private var focusedField: FocusedField?
    private let processor = MarkdownProcessor()
    
    @State private var isExporting = false
    @State private var exportURL: URL? = nil
    @State private var exportDocument: MarkdownDocument? = nil

    private var hasLocation: Bool {
        return entry?.locationName != nil || entry?.coordinate != nil
    }

    enum FocusedField {
        case title
        case tags
        case body
    }

    var body: some View {
        Group {
            if let currentEntry = entry {
                editorContent(for: currentEntry)
            } else {
                emptyStateView
            }
        }
        .onChange(of: locationManager.location) { oldValue, newValue in
            guard var e = entry else { return }
            if let loc = newValue {
                e.latitude = loc.coordinate.latitude
                e.longitude = loc.coordinate.longitude
                // Update binding first so UI reflects immediately
                entry = e
                // Persist change
                store.updateEntry(e)
            }
        }
        .onChange(of: locationManager.locationName) { oldName, newName in
            guard var e = entry else { return }
            if let name = newName {
                e.locationName = name
                entry = e
                store.updateEntry(e)
            } else if e.locationName == nil, e.coordinate != nil {
                // Fallback to coordinates string if reverse geocoding fails
                e.locationName = formatCoordinate(e)
                entry = e
                store.updateEntry(e)
            }
        }
        .fileImporter(
            isPresented: $isImporterPresented,
            allowedContentTypes: [.image],
            allowsMultipleSelection: true
        ) { result in
            switch result {
            case .success(let urls):
                for url in urls {
                    // Start accessing security scoped resource
                    guard url.startAccessingSecurityScopedResource() else { continue }
                    defer { url.stopAccessingSecurityScopedResource() }

                    if let data = try? Data(contentsOf: url),
                        let savedFilename = store.saveMedia(
                            data: data, fileExtension: url.pathExtension)
                    {
                        editedPhotoPaths.append(savedFilename)
                    }
                }
                saveEntry()
            case .failure(let error):
                print("Import failed: \(error.localizedDescription)")
            }
        }
        .overlay {
            if let url = expandedImage, let nsImage = NSImage(contentsOf: url) {
                ZStack {
                    Color.black.opacity(0.9)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation {
                                expandedImage = nil
                            }
                        }

                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(40)
                }
                .transition(.opacity)
                .zIndex(100)
            }
        }
        .animation(.easeInOut, value: expandedImage)
    }

    @ViewBuilder
    private func editorContent(for currentEntry: JournalEntry) -> some View {
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

                // Tags editor / viewer
                if isEditing {
                    TagsInputView(tags: $editedTags, focusTrigger: $tagsFocusTrigger)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 8)
                } else if !currentEntry.tags.isEmpty {
                    // Display tags as chips when not editing
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(currentEntry.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.vertical, 4)
                                    .padding(.horizontal, 8)
                                    .background(
                                        Capsule().fill(Color.secondary.opacity(0.15))
                                    )
                                    .overlay(
                                        Capsule().stroke(
                                            Color.secondary.opacity(0.3), lineWidth: 0.5)
                                    )
                            }
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.bottom, 8)
                }

                // Photo Attachments
                if !editedPhotoPaths.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(editedPhotoPaths, id: \.self) { path in
                                if let nsImage = NSImage(
                                    contentsOf: store.getAttachmentURL(path: path))
                                {
                                    Image(nsImage: nsImage)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipShape(RoundedRectangle(cornerRadius: 8))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                        )
                                        .onTapGesture {
                                            expandedImage = store.getAttachmentURL(path: path)
                                        }
                                        .contextMenu {
                                            Button(role: .destructive) {
                                                if let index = editedPhotoPaths.firstIndex(of: path)
                                                {
                                                    editedPhotoPaths.remove(at: index)
                                                    saveEntry()
                                                }
                                            } label: {
                                                Label("Remove Photo", systemImage: "trash")
                                            }
                                        }
                                }
                            }
                        }
                        .padding(.horizontal, 22)
                    }
                    .padding(.bottom, 8)
                }

                // Location Chip
                if currentEntry.locationName != nil || currentEntry.coordinate != nil {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "location.fill")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(currentEntry.locationName ?? formatCoordinate(currentEntry))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(8)

                        Spacer()

                        Button(role: .destructive) {
                            var updated = currentEntry
                            updated.locationName = nil
                            updated.latitude = nil
                            updated.longitude = nil
                            store.updateEntry(updated)
                            // Also update the binding so UI reflects immediately
                            entry = updated
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 8)
                }

                // Audio Attachments
                if !editedAudioPaths.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(editedAudioPaths, id: \.self) { path in
                            HStack {
                                SimpleAudioPlayer(url: store.getAttachmentURL(path: path))
                                Text("Audio Note")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Button(role: .destructive) {
                                    if let index = editedAudioPaths.firstIndex(of: path) {
                                        editedAudioPaths.remove(at: index)
                                        saveEntry()
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.secondary)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 8)
                }

                if isEditing {
                    FrontmatterEditorView(frontmatter: $editedFrontmatter)
                        .padding(.horizontal, 22)
                        .padding(.bottom, 8)
                } else if let fm = editedFrontmatter, !fm.isEmpty {
                    // Show a summary of frontmatter when not editing
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(fm.keys.sorted(), id: \.self) { key in
                            HStack {
                                Text(key + ":")
                                    .fontWeight(.medium)
                                Text("\(String(describing: fm[key]?.anyValue ?? ""))")
                                    .foregroundStyle(.secondary)
                            }
                            .font(.caption)
                        }
                    }
                    .padding(.horizontal, 22)
                    .padding(.bottom, 8)
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
            .onChange(of: editedTags) {
                saveEntry()
            }
            .onChange(of: editedFrontmatter) {
                saveEntry()
            }
            .onAppear {
                loadEntryState(currentEntry)
            }
            .onChange(of: entry?.id) {
                // Reset state when switching entries
                isEditing = false
                focusedField = nil

                if let newEntry = entry {
                    loadEntryState(newEntry)
                }
            }
            .toolbar {
                toolbarContent
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
            .fileExporter(
                isPresented: $isExporting,
                document: exportDocument,
                contentType: .plainText,
                defaultFilename: (entry?.displayTitle ?? "Entry") + ".md"
            ) { result in
                if case .failure(let error) = result {
                    print("Export failed: \(error.localizedDescription)")
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
    }

    private var emptyStateView: some View {
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

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
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

                Button(action: {
                    if !isEditing { isEditing = true }
                    tagsFocusTrigger.toggle()
                }) {
                    Label("Tags", systemImage: "tag")
                }
                .keyboardShortcut("t", modifiers: .command)
                .help("Edit tags")

                Spacer()

                Button(action: {
                    isImporterPresented = true
                }) {
                    Label("Add Photo", systemImage: "photo")
                }
                .disabled(false)

                Button(action: {}) {
                    Label("Take a Picture", systemImage: "camera")
                }
                .disabled(true)

                Button(action: {
                    locationManager.requestLocation()
                }) {
                    Label(hasLocation ? "Update Location" : "Add Location",
                          systemImage: hasLocation ? "location.fill" : "location")
                }
                .help(hasLocation ? "Update the saved location" : "Attach your current location")
                .disabled(false)

                Button(action: {
                    if audioRecorder.isRecording {
                        if let url = audioRecorder.stopRecording(),
                            let data = try? Data(contentsOf: url),
                            let savedFilename = store.saveMedia(data: data, fileExtension: "m4a")
                        {
                            editedAudioPaths.append(savedFilename)
                            saveEntry()  // Auto-save after recording
                        }
                    } else {
                        audioRecorder.startRecording()
                    }
                }) {
                    Label(
                        audioRecorder.isRecording ? "Stop Recording" : "Record Audio",
                        systemImage: audioRecorder.isRecording ? "stop.circle.fill" : "waveform"
                    )
                    .foregroundStyle(audioRecorder.isRecording ? .red : .primary)
                }
                .disabled(false)

                ShareLink(item: entry?.content ?? "")

                Button(action: {
                    prepareExport()
                }) {
                    Label("Export as Markdown", systemImage: "square.and.arrow.up")
                }
                .help("Export as Markdown file")

                Spacer()

                Button(action: { showDeleteConfirmation = true }) {
                    Label("Delete", systemImage: "trash")
                }
                .help("Move to Trash")
            }
        }
    }

    private func loadEntryState(_ currentEntry: JournalEntry) {
        editedContent = currentEntry.content
        editedTitle = currentEntry.title ?? ""
        editedTags = currentEntry.tags
        editedPhotoPaths = currentEntry.photoPaths
        editedAudioPaths = currentEntry.audioPaths
        editedFrontmatter = currentEntry.frontmatter
        // Auto-edit if new/empty
        if currentEntry.content.isEmpty {
            isEditing = true
            focusedField = .title
        }
    }

    private func formatCoordinate(_ entry: JournalEntry) -> String {
        if let coord = entry.coordinate {
            let lat = String(format: "%.4f", coord.latitude)
            let lon = String(format: "%.4f", coord.longitude)
            return "\(lat), \(lon)"
        }
        return "Location"
    }

    private func saveEntry() {
        guard var currentEntry = entry else { return }
        currentEntry.content = editedContent
        currentEntry.title = editedTitle.isEmpty ? nil : editedTitle

        currentEntry.tags = editedTags
        currentEntry.photoPaths = editedPhotoPaths
        currentEntry.audioPaths = editedAudioPaths
        currentEntry.frontmatter = editedFrontmatter

        store.updateEntry(currentEntry)
        // Update binding
        entry = currentEntry
    }

    private func prepareExport() {
        guard let currentEntry = entry else { return }
        
        // Generate frontmatter-enhanced markdown
        var fmString = "---\n"
        var fm: [String: Any] = [:]
        if let entryFM = currentEntry.frontmatter {
            for (k, v) in entryFM {
                fm[k] = v.anyValue
            }
        }
        
        fm["title"] = currentEntry.title
        fm["date"] = ISO8601DateFormatter().string(from: currentEntry.date)
        if !currentEntry.tags.isEmpty {
            fm["tags"] = currentEntry.tags
        }
        
        for (key, value) in fm.sorted(by: { $0.key < $1.key }) {
            if let val = value as? String {
                fmString += "\(key): \"\(val.replacingOccurrences(of: "\"", with: "\\\""))\"\n"
            } else if let val = value as? [String] {
                fmString += "\(key): [\(val.map { "\"\($0)\"" }.joined(separator: ", "))]\n"
            } else {
                fmString += "\(key): \(value)\n"
            }
        }
        fmString += "---\n\n"
        
        let fullContent = fmString + currentEntry.content
        exportDocument = MarkdownDocument(content: fullContent)
        isExporting = true
    }
}

struct SimpleAudioPlayer: View {
    let url: URL
    @State private var isPlaying = false
    @State private var player: AVAudioPlayer?
    @State private var duration: TimeInterval = 0

    var body: some View {
        Button(action: togglePlay) {
            Image(systemName: isPlaying ? "stop.circle.fill" : "play.circle.fill")
                .font(.title2)
                .foregroundStyle(.blue)
        }
        .buttonStyle(.plain)
        .onAppear {
            // Pre-load to get duration if needed, or simple setup
            if let p = try? AVAudioPlayer(contentsOf: url) {
                duration = p.duration
            }
        }
    }

    func togglePlay() {
        if isPlaying {
            player?.stop()
            isPlaying = false
        } else {
            do {
                player = try AVAudioPlayer(contentsOf: url)
                player?.delegate = nil  // In a real app, use delegate to reset state on finish
                player?.play()
                isPlaying = true

                // Simple auto-reset (hacky but works for demo)
                Timer.scheduledTimer(withTimeInterval: player?.duration ?? 0, repeats: false) { _ in
                    Task { @MainActor in
                        isPlaying = false
                    }
                }
            } catch {
                print("Play error: \(error)")
            }
        }
    }
}

struct MarkdownDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.plainText, .text] }
    var content: String

    init(content: String) {
        self.content = content
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents,
              let string = String(data: data, encoding: .utf8)
        else {
            throw CocoaError(.fileReadCorruptFile)
        }
        content = string
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let data = content.data(using: .utf8)!
        return .init(regularFileWithContents: data)
    }
}

