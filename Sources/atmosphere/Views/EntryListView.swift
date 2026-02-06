import SwiftUI

struct EntryListView: View {
    let journal: Journal?
    @Binding var selectedEntry: JournalEntry?
    @EnvironmentObject var store: JournalStore
    @State private var entryToEdit: JournalEntry?
    @State private var showDeleteConfirmation = false
    @State private var entryToDelete: JournalEntry?
    @State private var showEmptyTrashConfirmation = false

    var filteredEntries: [JournalEntry] {
        store.entries(for: journal)
    }

    var isTrashView: Bool {
        journal?.id == Journal.trashID
    }

    var body: some View {
        List(selection: $selectedEntry) {
            ForEach(filteredEntries) { entry in
                NavigationLink(value: entry) {
                    EntryRowView(entry: entry)
                }
                .swipeActions(edge: .trailing) {
                    if isTrashView {
                        Button(role: .destructive) {
                            entryToDelete = entry
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
                            entryToDelete = entry
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
                    if isTrashView {
                        Button {
                            store.restoreEntry(entry)
                        } label: {
                            Label("Restore", systemImage: "arrow.uturn.backward")
                        }

                        Divider()

                        Button(role: .destructive) {
                            entryToDelete = entry
                            showDeleteConfirmation = true
                        } label: {
                            Label("Delete Forever", systemImage: "trash.slash")
                        }
                    } else {
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
                            entryToDelete = entry
                            showDeleteConfirmation = true
                        } label: {
                            Label("Move to Trash", systemImage: "trash")
                        }
                    }
                }
            }
        }
        .navigationTitle(journal?.name ?? "Entries")
        .frame(minWidth: 250)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .controlBackgroundColor))
        .toolbar {
            ToolbarItem(placement: .navigation) {
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
        .alert("Delete Entry?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {
                entryToDelete = nil
            }
            Button(isTrashView ? "Delete Forever" : "Move to Trash", role: .destructive) {
                if let entry = entryToDelete {
                    if isTrashView {
                        store.permanentlyDeleteEntry(entry)
                    } else {
                        store.deleteEntry(entry)
                    }
                    if selectedEntry?.id == entry.id {
                        selectedEntry = nil
                    }
                    entryToDelete = nil
                }
            }
        } message: {
            Text(
                isTrashView
                    ? "This will permanently delete the entry. This action cannot be undone."
                    : "This entry will be moved to Trash. You can restore it later.")
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

    private func createNewEntry() {
        let newEntry = JournalEntry(
            content: "",
            journalIDs: journal.map { [$0.id] } ?? []
        )
        let addedEntry = store.addEntry(newEntry)
        selectedEntry = addedEntry
    }
}
