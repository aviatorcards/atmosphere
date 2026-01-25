import SwiftUI

struct EntryMetadataEditor: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var store: JournalStore

    @State private var title: String = ""
    @State private var tagsText: String = ""
    @State private var selectedJournalIDs: Set<UUID> = []

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Spacer()

                Text("Edit Entry Info")
                    .font(.headline)

                Spacer()

                Button("Save") {
                    saveChanges()
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding()

            Divider()

            Form {
                Section("Title") {
                    TextField("Entry title", text: $title)
                }

                Section("Tags") {
                    TextField("Comma-separated tags", text: $tagsText)
                    Text("Separate tags with commas (e.g., Work, Ideas, Personal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section("Journals") {
                    ForEach(store.journals.sorted(by: { $0.sortOrder < $1.sortOrder })) { journal in
                        Toggle(isOn: Binding(
                            get: { selectedJournalIDs.contains(journal.id) },
                            set: { isSelected in
                                if isSelected {
                                    selectedJournalIDs.insert(journal.id)
                                } else {
                                    selectedJournalIDs.remove(journal.id)
                                }
                            }
                        )) {
                            Label(journal.name, systemImage: journal.icon)
                        }
                    }
                }

                Section("Date") {
                    Text(entry.date.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }

                if let location = entry.locationName {
                    Section("Location") {
                        Text(location)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .formStyle(.grouped)
        }
        .frame(width: 400, height: 550)
        .onAppear {
            title = entry.title ?? ""
            tagsText = entry.tags.joined(separator: ", ")
            selectedJournalIDs = Set(entry.journalIDs)
        }
    }

    private func saveChanges() {
        var updatedEntry = entry
        updatedEntry.title = title.isEmpty ? nil : title
        updatedEntry.tags = tagsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        updatedEntry.journalIDs = Array(selectedJournalIDs)
        store.updateEntry(updatedEntry)
    }
}
