import SwiftUI

struct EditJournalView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: JournalStore

    let journal: Journal

    @State private var journalName: String
    @State private var selectedIcon: String
    @State private var selectedColorHex: String?
    @State private var showValidationError = false
    @State private var validationMessage = ""

    @FocusState private var isNameFieldFocused: Bool

    init(journal: Journal) {
        self.journal = journal
        _journalName = State(initialValue: journal.name)
        _selectedIcon = State(initialValue: journal.icon)
        _selectedColorHex = State(initialValue: journal.colorHex)
    }

    var isValid: Bool {
        !journalName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Edit Journal")
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: { dismiss() }) {
                    Image(systemName: "xmark.circle")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()

            Divider()

            // Form content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Name field
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Name")
                                .font(.headline)
                            Text("*")
                                .foregroundColor(.red)
                        }

                        TextField("Journal Name", text: $journalName)
                            .textFieldStyle(.roundedBorder)
                            .focused($isNameFieldFocused)
                            .disabled(journal.isDefault)

                        if journal.isDefault {
                            Text("Default journals cannot be renamed")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                if !journalName.isEmpty {
                                    Text("\(journalName.count)/50")
                                        .font(.caption)
                                        .foregroundColor(journalName.count > 50 ? .red : .secondary)
                                }
                            }
                        }
                    }

                    // Icon picker
                    IconPickerView(selectedIcon: $selectedIcon)

                    // Color picker
                    ColorSwatchPicker(selectedColorHex: $selectedColorHex)

                    // Preview
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Preview")
                            .font(.headline)

                        HStack {
                            Label(
                                journalName.isEmpty ? "Journal Name" : journalName,
                                systemImage: selectedIcon
                            )
                            .foregroundColor(
                                selectedColorHex != nil
                                    ? Color(hex: selectedColorHex!) : .accentColor
                            )
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)

                            Spacer()
                        }
                    }
                }
                .padding()
            }

            Divider()

            // Footer buttons
            HStack {
                if !journal.isDefault {
                    Button(role: .destructive) {
                        store.deleteJournal(journal)
                        dismiss()
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 14))
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.red)
                    .help("Delete Journal")
                }
                Spacer()

                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Save") {
                    saveChanges()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
            .padding()
        }
        .frame(width: 800, height: 650)
        .onAppear {
            if !journal.isDefault {
                isNameFieldFocused = true
            }
        }
        .alert("Invalid Journal", isPresented: $showValidationError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(validationMessage)
        }
    }

    private func saveChanges() {
        let trimmedName = journalName.trimmingCharacters(in: .whitespaces)

        // Validate name (only if not default journal)
        if !journal.isDefault {
            guard !trimmedName.isEmpty else {
                validationMessage = "Journal name cannot be empty"
                showValidationError = true
                return
            }

            guard trimmedName.count <= 50 else {
                validationMessage = "Journal name must be 50 characters or less"
                showValidationError = true
                return
            }
        }

        // Create updated journal
        var updatedJournal = journal
        updatedJournal.name = journal.isDefault ? journal.name : trimmedName
        updatedJournal.icon = selectedIcon
        updatedJournal.colorHex = selectedColorHex

        store.updateJournal(updatedJournal)
        dismiss()
    }
}
