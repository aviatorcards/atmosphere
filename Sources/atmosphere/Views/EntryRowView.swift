import SwiftUI

struct EntryRowView: View {
    let entry: JournalEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header: Date & Bookmark
            HStack {
                Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Spacer()

                if entry.isBookmarked {
                    Image(systemName: "bookmark.fill")
                        .font(.caption)
                        .foregroundStyle(.yellow)
                }
            }

            // Title
            Text(entry.displayTitle)
                .font(.headline)
                .lineLimit(1)

            // Preview Content
            Text(entry.content)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            // Footer: Tags & Location
            if !entry.tags.isEmpty || entry.locationName != nil {
                HStack {
                    if let location = entry.locationName {
                        Label(location, systemImage: "mappin.and.ellipse")
                    }

                    ForEach(entry.tags, id: \.self) { tag in
                        Text("#\(tag)")
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 8)
        #if os(macOS)
            .contentShape(Rectangle())  // Improves clickability
        #endif
    }
}
