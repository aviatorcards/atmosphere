import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: JournalStore

    enum Pane: Hashable {
        case general
    }

    @State private var selection: Pane = .general

    var body: some View {
        #if os(macOS)
            NavigationSplitView(
                sidebar: {
                    List(selection: $selection) {
                        Label("General", systemImage: "gear").tag(Pane.general)
                    }
                    .listStyle(.sidebar)
                    .frame(minWidth: 180)
                },
                detail: {
                    switch selection {
                    case .general:
                        GeneralSettingsPane()
                            .environmentObject(store)
                    }
                }
            )
            .navigationTitle("Settings")
        #else
            // Placeholder for non-macOS platforms
            Text("Settings are only available on macOS in this build.")
        #endif
    }
}

private struct GeneralSettingsPane: View {
    @EnvironmentObject var store: JournalStore

    var journalsSorted: [Journal] {
        store.journals.sorted(by: { $0.sortOrder < $1.sortOrder })
    }

    var automaticID = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!

    var body: some View {
        Form {
            Section(header: Text("Default Journal")) {
                Picker(
                    "Default Journal",
                    selection: Binding(
                        get: { store.preferredDefaultJournalID ?? automaticID },
                        set: { newValue in
                            DispatchQueue.main.async {
                                if newValue == automaticID {
                                    store.preferredDefaultJournalID = nil
                                    store.preferredDefaultJournalID = newValue
                                }
                            }
                        }
                    )
                ) {
                    Text("Automatic (Personal or first)").tag(automaticID)
                    ForEach(journalsSorted) { journal in
                        HStack {
                            Image(systemName: journal.icon)
                            Text(journal.name)
                        }
                        .tag(journal.id)
                    }
                }
                .pickerStyle(.segmented)
                Text(
                    "When set to Automatic, new entries created outside a specific journal will go to Personal if available, otherwise the first journal."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
            .environmentObject(JournalStore())
    }
}
