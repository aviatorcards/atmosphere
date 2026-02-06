import Combine
import Foundation

/// Manages persistence of journals and entries using JSON files
@MainActor
class JournalStore: ObservableObject {
    @Published var journals: [Journal] = []
    @Published var entries: [JournalEntry] = []

    // User preference for default journal
    private let preferredDefaultJournalKey = "preferredDefaultJournalID"
    @Published var preferredDefaultJournalID: UUID? {
        didSet { savePreferredDefaultJournalID() }
    }

    // Cache for tag journals to ensure stable IDs
    private var tagCache: [String: Journal] = [:]

    var tags: [Journal] {
        var tagLastUsed: [String: Date] = [:]

        // Find most recent usage of each tag
        for entry in entries where !entry.isDeleted {
            for tag in entry.tags {
                let date = entry.date
                if let existing = tagLastUsed[tag] {
                    if date > existing { tagLastUsed[tag] = date }
                } else {
                    tagLastUsed[tag] = date
                }
            }
        }

        let sortedTagNames = tagLastUsed.keys.sorted {
            let date1 = tagLastUsed[$0]!
            let date2 = tagLastUsed[$1]!
            if date1 != date2 {
                return date1 > date2
            }
            return $0.localizedStandardCompare($1) == .orderedAscending
        }

        return sortedTagNames.map { tagName in
            if let existing = tagCache[tagName] {
                return existing
            }
            let new = Journal(
                id: UUID(),
                name: tagName,
                icon: "tag",
                isDefault: true,
                sortOrder: 100,  // Display at bottom
                tagFilter: tagName
            )
            tagCache[tagName] = new
            return new
        }
    }

    private func loadPreferredDefaultJournalID() {
        if let str = UserDefaults.standard.string(forKey: preferredDefaultJournalKey),
            let id = UUID(uuidString: str)
        {
            preferredDefaultJournalID = id
        } else {
            preferredDefaultJournalID = nil
        }
    }

    private func savePreferredDefaultJournalID() {
        if let id = preferredDefaultJournalID {
            UserDefaults.standard.set(id.uuidString, forKey: preferredDefaultJournalKey)
        } else {
            UserDefaults.standard.removeObject(forKey: preferredDefaultJournalKey)
        }
    }

    private let fileManager = FileManager.default
    private let journalsURL: URL
    private let entriesURL: URL
    let attachmentsDirectory: URL

    init() {
        // Get app support directory
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
            .first!
        let appDirectory = appSupport.appendingPathComponent("Atmosphere", isDirectory: true)

        // Create directory if needed
        try? fileManager.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        journalsURL = appDirectory.appendingPathComponent("journals.json")
        entriesURL = appDirectory.appendingPathComponent("entries.json")
        attachmentsDirectory = appDirectory.appendingPathComponent("Attachments", isDirectory: true)

        // Create attachments directory if needed
        try? fileManager.createDirectory(
            at: attachmentsDirectory, withIntermediateDirectories: true)

        loadData()
        loadPreferredDefaultJournalID()
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
        // One-time fix-up to ensure all entries belong to a real journal
        sanitizeEntriesAfterLoad()
    }

    // MARK: - Helpers

    private func isSpecialJournalID(_ id: UUID) -> Bool {
        return id == Journal.allEntriesID || id == Journal.mapID || id == Journal.trashID
    }

    private func sanitizeJournalIDs(_ ids: [UUID]) -> [UUID] {
        // Remove any special collection IDs and duplicates while preserving order
        var seen = Set<UUID>()
        var result: [UUID] = []
        for id in ids where !isSpecialJournalID(id) {
            if !seen.contains(id) {
                seen.insert(id)
                result.append(id)
            }
        }
        return result
    }

    // Ensure existing entries have valid journal assignments after load
    private func sanitizeEntriesAfterLoad() {
        var changed = false
        for i in entries.indices {
            // Remove special collection IDs and duplicates
            let cleaned = sanitizeJournalIDs(entries[i].journalIDs)
            if cleaned != entries[i].journalIDs {
                entries[i].journalIDs = cleaned
                changed = true
            }
            // Assign default if no journals remain
            if entries[i].journalIDs.isEmpty {
                entries[i].journalIDs = [defaultJournalID]
                changed = true
            }
        }
        if changed {
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

    func saveMedia(data: Data, fileExtension: String) -> String? {
        let id = UUID().uuidString
        let filename = "\(id).\(fileExtension)"
        let fileURL = attachmentsDirectory.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, options: .atomic)
            return filename
        } catch {
            print("Error saving media: \(error)")
            return nil
        }
    }

    func getAttachmentURL(path: String) -> URL {
        return attachmentsDirectory.appendingPathComponent(path)
    }

    // MARK: - CRUD Operations

    @discardableResult
    func addEntry(_ entry: JournalEntry) -> JournalEntry {
        var newEntry = entry
        // Ensure entry has a valid home journal
        let cleaned = sanitizeJournalIDs(newEntry.journalIDs)
        if cleaned.isEmpty {
            newEntry.journalIDs = [defaultJournalID]
        } else {
            newEntry.journalIDs = cleaned
        }
        entries.append(newEntry)
        saveEntries()
        return newEntry
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
        if preferredDefaultJournalID == journal.id { preferredDefaultJournalID = nil }
        // Remove journal ID from all entries
        for i in entries.indices {
            entries[i].journalIDs.removeAll { $0 == journal.id }
            // If an entry has no journals left, move it to the default journal
            if entries[i].journalIDs.isEmpty {
                entries[i].journalIDs = [defaultJournalID]
            }
        }
        saveJournals()
        saveEntries()
    }

    // MARK: - Queries

    var defaultJournalID: UUID {
        // If user has selected a preferred default and it still exists, use it
        if let preferred = preferredDefaultJournalID,
            journals.contains(where: { $0.id == preferred })
        {
            return preferred
        }
        // Prefer Personal if present, else first available journal
        if journals.contains(where: { $0.id == Journal.personalID }) {
            return Journal.personalID
        }
        return journals.first?.id ?? Journal.personalID
    }

    func entries(for journal: Journal?) -> [JournalEntry] {
        guard let journal = journal else {
            return entries.filter { !$0.isDeleted }
        }

        // Trash - show only deleted entries
        if journal.id == Journal.trashID {
            return entries.filter { $0.isDeleted }.sorted {
                ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast)
            }
        }

        // Tag filter
        if let tagFilter = journal.tagFilter {
            return entries.filter { !$0.isDeleted && $0.tags.contains(tagFilter) }.sorted {
                $0.date > $1.date
            }
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
        return activeEntries.filter { $0.journalIDs.contains(journal.id) }.sorted {
            $0.date > $1.date
        }
    }

    var trashedEntries: [JournalEntry] {
        entries.filter { $0.isDeleted }.sorted {
            ($0.deletedAt ?? .distantPast) > ($1.deletedAt ?? .distantPast)
        }
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
