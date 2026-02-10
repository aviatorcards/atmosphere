import SwiftUI

struct EntryListView: View {
    let journal: Journal?
    @Binding var selectedEntry: JournalEntry?
    #if os(macOS)
        @State private var selectedEntryIDs: Set<JournalEntry.ID> = []
    #endif
    @EnvironmentObject var store: JournalStore
    @State private var entriesToDelete: [JournalEntry] = []
    @State private var entryToEdit: JournalEntry?
    @State private var showDeleteConfirmation = false
    @State private var showEmptyTrashConfirmation = false

    var filteredEntries: [JournalEntry] {
        store.entries(for: journal)
    }

    var isTrashView: Bool {
        journal?.id == Journal.trashID
    }

    var body: some View {
        platformList
            .navigationTitle(journal?.name ?? "Entries")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if isTrashView {
                        Button(action: { showEmptyTrashConfirmation = true }) {
                            Label("Empty Trash", systemImage: "trash.slash")
                        }
                        .disabled(filteredEntries.isEmpty)
                    } else {
                        Button(action: createNewEntry) {
                            Label("New Entry", systemImage: "square.and.pencil")
                        }
                    }
                }
            }
            .sheet(item: $entryToEdit) { entry in
                EntryMetadataEditor(entry: entry)
            }
            .alert(
                "Delete \(entriesToDelete.count > 1 ? "\(entriesToDelete.count) Entries" : "Entry")?",
                isPresented: $showDeleteConfirmation
            ) {
                Button("Cancel", role: .cancel) {
                    entriesToDelete = []
                }
                Button(isTrashView ? "Delete Forever" : "Move to Trash", role: .destructive) {
                    if isTrashView {
                        for entry in entriesToDelete {
                            store.permanentlyDeleteEntry(entry)
                        }
                    } else {
                        for entry in entriesToDelete {
                            store.deleteEntry(entry)
                        }
                    }

                    // Clear selection if deleted
                    #if os(macOS)
                        let deletedIDs = Set(entriesToDelete.map { $0.id })
                        selectedEntryIDs.subtract(deletedIDs)
                        if let selected = selectedEntry, deletedIDs.contains(selected.id) {
                            selectedEntry = nil
                        }
                    #else
                        if let selected = selectedEntry,
                            entriesToDelete.contains(where: { $0.id == selected.id })
                        {
                            selectedEntry = nil
                        }
                    #endif

                    entriesToDelete = []
                }
            } message: {
                Text(
                    isTrashView
                        ? "This will permanently delete the selected entries. This action cannot be undone."
                        : "Selected entries will be moved to Trash. You can restore them later.")
            }
            .alert("Empty Trash?", isPresented: $showEmptyTrashConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Empty Trash", role: .destructive) {
                    store.emptyTrash()
                    selectedEntry = nil
                }
            } message: {
                Text(
                    "This will permanently delete all \(filteredEntries.count) entries in Trash. This action cannot be undone."
                )
            }
    }

    @ViewBuilder
    private var platformList: some View {
        #if os(macOS)
            List(selection: $selectedEntryIDs) {
                entryRows
            }
            .onChange(of: selectedEntryIDs) { _, new in
                // Only update single selection if it contradicts the set
                // or if we want to sync the detail view to the last selected item
                if let lastID = new.first {  // Set is unordered, just picking one for detail view
                    if let match = filteredEntries.first(where: { $0.id == lastID }) {
                        selectedEntry = match
                    }
                } else {
                    selectedEntry = nil
                }
            }
            .frame(minWidth: 250)
            .scrollContentBackground(.hidden)
            .background(Color(nsColor: .controlBackgroundColor))
        #else
            List(selection: $selectedEntry) {
                entryRows
            }
        #endif
    }

    private var entryRows: some View {
        ForEach(filteredEntries) { entry in
            NavigationLink(value: entry) {
                EntryRowView(entry: entry)
            }
            .tag(entry.id)
            .swipeActions(edge: .trailing) {
                if isTrashView {
                    Button(role: .destructive) {
                        entriesToDelete = [entry]
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete Forever", systemImage: "trash.slash")
                    }

                    Button {
                        store.restoreEntry(entry)
                    } label: {
                        Label("Restore", systemImage: "arrow.uturn.backward")
                    }
                    .tint(.green)
                } else {
                    Button(role: .destructive) {
                        entriesToDelete = [entry]
                        showDeleteConfirmation = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }

                    Button {
                        store.toggleBookmark(entry)
                    } label: {
                        Label(
                            entry.isBookmarked ? "Unbookmark" : "Bookmark",
                            systemImage: entry.isBookmarked ? "bookmark.fill" : "bookmark")
                    }
                    .tint(.yellow)
                }
            }
            .contextMenu {
                #if os(macOS)
                    // macOS Context Menu with Bulk Actions
                    if selectedEntryIDs.contains(entry.id), selectedEntryIDs.count > 1 {
                        Text("\(selectedEntryIDs.count) Selected")

                        Menu("Move to...") {
                            ForEach(store.journals) { journal in
                                Button(journal.name) {
                                    moveSelectedEntries(to: journal)
                                }
                            }
                        }

                        Divider()

                        if isTrashView {
                            Button {
                                restoreSelectedEntries()
                            } label: {
                                Label("Restore Selected", systemImage: "arrow.uturn.backward")
                            }

                            Button(role: .destructive) {
                                deleteSelectedEntries()
                            } label: {
                                Label("Delete Selected Forever", systemImage: "trash.slash")
                            }
                        } else {
                            Button(role: .destructive) {
                                deleteSelectedEntries()
                            } label: {
                                Label("Move Selected to Trash", systemImage: "trash")
                            }
                        }
                    } else {
                        // Single Item Actions
                        singleItemContextMenu(for: entry)
                    }
                #else
                    // iOS Context Menu
                    singleItemContextMenu(for: entry)
                #endif
            }
        }
    }

    @ViewBuilder
    private func singleItemContextMenu(for entry: JournalEntry) -> some View {
        if isTrashView {
            Button {
                store.restoreEntry(entry)
            } label: {
                Label("Restore", systemImage: "arrow.uturn.backward")
            }

            Divider()

            Button(role: .destructive) {
                entriesToDelete = [entry]
                showDeleteConfirmation = true
            } label: {
                Label("Delete Forever", systemImage: "trash.slash")
            }
        } else {
            Menu("Move to...") {
                ForEach(store.journals) { journal in
                    Button(journal.name) {
                        moveEntries([entry], to: journal)
                    }
                }
            }

            Button {
                entryToEdit = entry
            } label: {
                Label("Edit Info", systemImage: "info.circle")
            }

            Button {
                store.toggleBookmark(entry)
            } label: {
                Label(
                    entry.isBookmarked ? "Remove Bookmark" : "Add Bookmark",
                    systemImage: entry.isBookmarked ? "bookmark.slash" : "bookmark")
            }

            Divider()

            Button(role: .destructive) {
                entriesToDelete = [entry]
                showDeleteConfirmation = true
            } label: {
                Label("Move to Trash", systemImage: "trash")
            }
        }
    }

    private func createNewEntry() {
        let newEntry = JournalEntry(
            content: "",
            journalIDs: journal.map { [$0.id] } ?? []
        )
        let addedEntry = store.addEntry(newEntry)
        selectedEntry = addedEntry
    }

    #if os(macOS)
        private func moveSelectedEntries(to targetJournal: Journal) {
            let entriesToMove = store.entries.filter { selectedEntryIDs.contains($0.id) }
            moveEntries(entriesToMove, to: targetJournal)
        }

        private func deleteSelectedEntries() {
            let entries = store.entries.filter { selectedEntryIDs.contains($0.id) }
            entriesToDelete = entries
            showDeleteConfirmation = true
        }

        private func restoreSelectedEntries() {
            let entries = store.entries.filter { selectedEntryIDs.contains($0.id) }
            for entry in entries {
                store.restoreEntry(entry)
            }
            selectedEntryIDs.removeAll()
        }
    #endif

    private func moveEntries(_ entries: [JournalEntry], to targetJournal: Journal) {
        for var entry in entries {
            // Keep existing logic: ensure it has the new journal ID
            // If we want to MOVE, we replace the IDs.
            // "Move" usually implies taking it out of current context and putting it in new one.
            // But an entry can belong to multiple journals potentially?
            // The request says "move entries from one journal to another".
            // Implementation: Replace journalIDs with [targetJournal.id]
            entry.journalIDs = [targetJournal.id]
            store.updateEntry(entry)
        }
    }
}
