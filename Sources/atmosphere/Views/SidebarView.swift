import SwiftUI

struct SidebarView: View {
    @Binding var selectedJournal: Journal?
    @EnvironmentObject var store: JournalStore
    @State private var showNewJournalSheet = false
    @State private var journalToEdit: Journal?

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
                        Label(journal.name, systemImage: journal.icon)
                            .foregroundColor(
                                journal.colorHex != nil ? Color(hex: journal.colorHex!) : nil
                            )
                    }
                    .contextMenu {
                        Button {
                            journalToEdit = journal
                        } label: {
                            Label("Edit Journal", systemImage: "pencil")
                        }

                        if !journal.isDefault {
                            Divider()

                            Button(role: .destructive) {
                                store.deleteJournal(journal)
                                if selectedJournal?.id == journal.id {
                                    selectedJournal = Journal.all
                                }
                            } label: {
                                Label("Delete Journal", systemImage: "trash")
                            }
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
    }
}
