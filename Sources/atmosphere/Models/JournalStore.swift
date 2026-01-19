import Combine
import Foundation

/// Manages persistence of journals and entries using JSON files
@MainActor
class JournalStore: ObservableObject {
    @Published var journals: [Journal] = []
    @Published var entries: [JournalEntry] = []

    private let fileManager = FileManager.default
    private let journalsURL: URL
    private let entriesURL: URL

    init() {
        // Get app support directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let appDirectory = appSupport.appendingPathComponent("Atmosphere", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        journalsURL = appDirectory.appendingPathComponent("journals.json")
        entriesURL = appDirectory.appendingPathComponent("entries.json")

        loadData()
    }

    // MARK: - Loading

    private func loadData() {
        loadJournals()
        loadEntries()
    }

    private func loadJournals() {
        if fileManager.fileExists(atPath: journalsURL.path) {
            do {
                let data = try Data(contentsOf: journalsURL)
                journals = try JSONDecoder().decode([Journal].self, from: data)
            } catch {
                print("Error loading journals: \(error)")
                journals = Journal.createDefaults()
                saveJournals()
            }
        } else {
            // First launch - create defaults
            journals = Journal.createDefaults()
            saveJournals()
        }
    }

    private func loadEntries() {
        if fileManager.fileExists(atPath: entriesURL.path) {
            do {
                let data = try Data(contentsOf: entriesURL)
                entries = try JSONDecoder().decode([JournalEntry].self, from: data)
            } catch {
                print("Error loading entries: \(error)")
                entries = createSampleEntries()
                saveEntries()
            }
        } else {
            // First launch - create sample data
            entries = createSampleEntries()
            saveEntries()
        }
    }

    // MARK: - Saving

    func saveJournals() {
        do {
            let data = try JSONEncoder().encode(journals)
            try data.write(to: journalsURL, options: .atomic)
        } catch {
            print("Error saving journals: \(error)")
        }
    }

    func saveEntries() {
        do {
            let data = try JSONEncoder().encode(entries)
            try data.write(to: entriesURL, options: .atomic)
        } catch {
            print("Error saving entries: \(error)")
        }
    }

    // MARK: - CRUD Operations

    func addEntry(_ entry: JournalEntry) {
        entries.append(entry)
        saveEntries()
    }

    func updateEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index] = entry
            saveEntries()
        }
    }

    func deleteEntry(_ entry: JournalEntry) {
        // Soft delete - move to trash
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].deletedAt = Date()
            saveEntries()
        }
    }

    func restoreEntry(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].deletedAt = nil
            saveEntries()
        }
    }

    func permanentlyDeleteEntry(_ entry: JournalEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
    }

    func emptyTrash() {
        entries.removeAll { $0.isDeleted }
        saveEntries()
    }

    func toggleBookmark(_ entry: JournalEntry) {
        if let index = entries.firstIndex(where: { $0.id == entry.id }) {
            entries[index].isBookmarked.toggle()
            saveEntries()
        }
    }

    func addJournal(_ journal: Journal) {
        journals.append(journal)
        saveJournals()
    }

    func updateJournal(_ journal: Journal) {
        if let index = journals.firstIndex(where: { $0.id == journal.id }) {
            journals[index] = journal
            saveJournals()
        }
    }

    func deleteJournal(_ journal: Journal) {
        journals.removeAll { $0.id == journal.id }
        // Remove journal ID from all entries
        for i in entries.indices {
            entries[i].journalIDs.removeAll { $0 == journal.id }
        }
        saveJournals()
        saveEntries()
    }

    // MARK: - Queries

    func entries(for journal: Journal?) -> [JournalEntry] {
        guard let journal = journal else {
            return entries.filter { !$0.isDeleted }
        }

        // Trash - show only deleted entries
        if journal.id == Journal.trashID {
            return entries.filter { $0.isDeleted }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
        }

        // All other views exclude deleted entries
        let activeEntries = entries.filter { !$0.isDeleted }

        // Special collections
        if journal.id == Journal.allEntriesID {
            return activeEntries.sorted { $0.date > $1.date }
        }

        if journal.id == Journal.mapID {
            return activeEntries.filter { $0.coordinate != nil }.sorted { $0.date > $1.date }
        }

        // Regular journals
        return activeEntries.filter { $0.journalIDs.contains(journal.id) }.sorted { $0.date > $1.date }
    }

    var trashedEntries: [JournalEntry] {
        entries.filter { $0.isDeleted }.sorted { ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast) }
    }

    // MARK: - Sample Data

    private func createSampleEntries() -> [JournalEntry] {
        let personalID = Journal.personalID
        let workID = Journal.workID
        let ideasID = Journal.ideasID

        return [
            JournalEntry(
                content: "Visited the new coffee shop downtown. The latte art was amazing! ☕️",
                title: "Coffee Shop Vibes",
                tags: ["Food", "Local"],
                locationName: "Downtown Coffee Co.",
                latitude: 37.7749,
                longitude: -122.4194,
                isBookmarked: true,
                journalIDs: [personalID]
            ),
            JournalEntry(
                content: "Long hike today. The view from the top was worth the struggle.",
                title: "Sunday Hike",
                tags: ["Fitness", "Nature"],
                latitude: 37.7914,
                longitude: -122.399,
                journalIDs: [personalID]
            ),
            JournalEntry(
                content:
                    "# Ideas for Atmosphere\n- Add map view\n- Fix sidebar\n- Add search\n\nThese features will really make the app shine!",
                tags: ["Dev", "Ideas"],
                locationName: "Home Office",
                latitude: 37.779,
                longitude: -122.418,
                journalIDs: [ideasID]
            ),
            JournalEntry(
                content: "Quarterly planning meeting went well. Team is aligned on Q1 goals.",
                title: "Q1 Planning",
                tags: ["Work", "Planning"],
                journalIDs: [workID]
            ),
        ]
    }
}
