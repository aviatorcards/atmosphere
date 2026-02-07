import SwiftUI

struct SidebarView: View {
    @Binding var selectedJournal: Journal?
    @EnvironmentObject var store: JournalStore
    @State private var showNewJournalSheet = false
    @State private var journalToEdit: Journal?
    @State private var journalToDelete: Journal?
    @State private var showingDeleteConfirmation = false
    @State private var isTagsExpanded = false
    @State private var tagSearchText = ""

    private var displayedTags: [Journal] {
        if !tagSearchText.isEmpty {
            return store.tags.filter { $0.name.localizedCaseInsensitiveContains(tagSearchText) }
        }
        return isTagsExpanded ? store.tags : Array(store.tags.prefix(5))
    }

    var body: some View {
        List(selection: $selectedJournal) {
            Section("Library") {
                NavigationLink(value: Journal.all) {
                    Label(Journal.all.name, systemImage: Journal.all.icon)
                }
                NavigationLink(value: Journal.map) {
                    Label(Journal.map.name, systemImage: Journal.map.icon)
                }
            }

            Section {
                ForEach(store.journals.sorted(by: { $0.sortOrder < $1.sortOrder })) { journal in
                    NavigationLink(value: journal) {
                        Label {
                            Text(journal.name)
                                .foregroundColor(.primary)
                        } icon: {
                            Image(systemName: journal.icon)
                                .foregroundColor(
                                    journal.colorHex != nil
                                        ? Color(hex: journal.colorHex!) : .primary
                                )
                        }
                    }
                    .contextMenu {
                        Button {
                            journalToEdit = journal
                        } label: {
                            Label("Edit Journal", systemImage: "pencil")
                        }

                        if store.journals.count > 1 {
                            Divider()

                            Button(role: .destructive) {
                                journalToDelete = journal
                                showingDeleteConfirmation = true
                            } label: {
                                Label("Delete Journal", systemImage: "trash")
                            }
                        }
                    }
                }
                .onDelete { indexSet in
                    let sortedJournals = store.journals.sorted(by: { $0.sortOrder < $1.sortOrder })
                    for index in indexSet {
                        let journal = sortedJournals[index]
                        if store.journals.count > 1 {
                            journalToDelete = journal
                            showingDeleteConfirmation = true
                        }
                    }
                }
            } header: {
                HStack {
                    Text("Journals")
                    Spacer()
                    Button(action: { showNewJournalSheet = true }) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
                    .help("New Journal")
                }
            }

            if !store.tags.isEmpty {
                Section("Tags") {
                    if isTagsExpanded {
                        TextField("Filter Tags", text: $tagSearchText)
                            .textFieldStyle(.plain)
                            .padding(.vertical, 4)
                    }

                    ForEach(displayedTags) { tag in
                        NavigationLink(value: tag) {
                            Label(tag.name, systemImage: tag.icon)
                        }
                    }

                    if store.tags.count > 5 && tagSearchText.isEmpty {
                        Button {
                            withAnimation {
                                if isTagsExpanded { tagSearchText = "" }
                                isTagsExpanded.toggle()
                            }
                        } label: {
                            Label(
                                isTagsExpanded ? "Show Less" : "Show More",
                                systemImage: isTagsExpanded ? "chevron.up" : "chevron.down"
                            )
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            Section {
                NavigationLink(value: Journal.trash) {
                    Label(
                        Journal.trash.name,
                        systemImage: store.trashedEntries.isEmpty ? "trash" : "trash.fill")
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 200)
        .scrollContentBackground(.hidden)
        .background(Color(nsColor: .windowBackgroundColor))
        .sheet(isPresented: $showNewJournalSheet) {
            NewJournalView()
                .environmentObject(store)
        }
        .sheet(item: $journalToEdit) { journal in
            EditJournalView(journal: journal)
                .environmentObject(store)
        }
        .alert("Delete Journal?", isPresented: $showingDeleteConfirmation, presenting: journalToDelete) { journal in
            Button("Cancel", role: .cancel) {
                journalToDelete = nil
            }
            Button("Delete", role: .destructive) {
                store.deleteJournal(journal)
                if selectedJournal?.id == journal.id {
                    selectedJournal = Journal.all
                }
                journalToDelete = nil
            }
        } message: { journal in
            Text("Are you sure you want to delete '\(journal.name)'? All entries in this journal will remain in their other journals, or move to the default journal if this was their only one.")
        }
    }
}
