import CoreLocation
import Foundation

struct JournalEntry: Identifiable, Hashable, Codable {
    var id: UUID
    var date: Date
    var content: String
    var title: String?
    var tags: [String]

    // Multimedia - store as file URLs relative to app container
    var photoPaths: [String]
    var videoPaths: [String]
    var audioPaths: [String]

    // Location
    var locationName: String?
    var latitude: Double?
    var longitude: Double?

    var isBookmarked: Bool

    // Journal relationships (store IDs)
    var journalIDs: [UUID]

    // Soft delete - nil means not deleted
    var deletedAt: Date?

    var frontmatter: [String: CodableValue]?

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        content: String,
        title: String? = nil,
        tags: [String] = [],
        photoPaths: [String] = [],
        videoPaths: [String] = [],
        audioPaths: [String] = [],
        locationName: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        isBookmarked: Bool = false,
        journalIDs: [UUID] = [],
        deletedAt: Date? = nil,
        frontmatter: [String: CodableValue]? = nil
    ) {
        self.id = id
        self.date = date
        self.content = content
        self.title = title
        self.tags = tags
        self.photoPaths = photoPaths
        self.videoPaths = videoPaths
        self.audioPaths = audioPaths
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.isBookmarked = isBookmarked
        self.journalIDs = journalIDs
        self.deletedAt = deletedAt
        self.frontmatter = frontmatter
    }

    var isDeleted: Bool {
        deletedAt != nil
    }

    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        }
        // Extract first line of content or fallback
        let lines = content.components(separatedBy: .newlines)
        if let first = lines.first(where: { !$0.isEmpty }) {
            return first.replacingOccurrences(of: "#", with: "").trimmingCharacters(
                in: .whitespaces)
        }
        return "Untitled Entry"
    }

    var coordinate: CLLocationCoordinate2D? {
        guard let lat = latitude, let lon = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: lat, longitude: lon)
    }
}
