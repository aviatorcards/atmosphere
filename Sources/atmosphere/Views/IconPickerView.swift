import SwiftUI

// Icon collections
private let allIcons = [
    // Work
    "briefcase", "desktopcomputer", "laptopcomputer", "chart.bar", "folder", "doc.text", "calendar",
    "clock", "paperclip", "envelope",
    // Personal
    "person.text.rectangle", "heart", "house", "star", "sparkles", "gift", "balloon",
    "party.popper", "crown", "leaf",
    // Activities
    "figure.run", "figure.walk", "bicycle", "airplane", "car", "fork.knife", "cup.and.saucer",
    "camera", "gamecontroller", "music.note",
    // Objects
    "book.closed", "books.vertical", "pencil", "paintbrush", "wrench", "hammer", "lightbulb",
    "flag", "target", "trophy",
]

struct IconPickerView: View {
    @Binding var selectedIcon: String
    @State private var searchText = ""
    @State private var selectedCategory: IconCategory = .all

    enum IconCategory: String, CaseIterable {
        case all = "All"
        case work = "Work"
        case personal = "Personal"
        case activities = "Activities"
        case objects = "Objects"

        var icons: [String] {
            switch self {
            case .all:
                return allIcons
            case .work:
                return [
                    "briefcase", "desktopcomputer", "laptopcomputer", "chart.bar", "folder",
                    "doc.text", "calendar", "clock", "paperclip", "envelope",
                ]
            case .personal:
                return [
                    "person.text.rectangle", "heart", "house", "star", "sparkles", "gift",
                    "balloon", "party.popper", "crown", "leaf",
                ]
            case .activities:
                return [
                    "figure.run", "figure.walk", "bicycle", "airplane", "car", "fork.knife",
                    "cup.and.saucer", "camera", "gamecontroller", "music.note",
                ]
            case .objects:
                return [
                    "book.closed", "books.vertical", "pencil", "paintbrush", "wrench", "hammer",
                    "lightbulb", "flag", "target", "trophy",
                ]
            }
        }
    }

    var filteredIcons: [String] {
        let categoryIcons = selectedCategory.icons

        if searchText.isEmpty {
            return categoryIcons
        }

        return categoryIcons.filter { icon in
            icon.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Icon")
                .font(.headline)

            // Category tabs
            Picker("Category", selection: $selectedCategory) {
                ForEach(IconCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)

            // Search field
            TextField("Search icons...", text: $searchText)
                .textFieldStyle(.roundedBorder)

            // Icon grid
            ScrollView {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 8),
                    spacing: 8
                ) {
                    ForEach(filteredIcons, id: \.self) { icon in
                        IconButton(
                            icon: icon,
                            isSelected: selectedIcon == icon
                        ) {
                            selectedIcon = icon
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .frame(height: 160)
        }
    }
}

struct IconButton: View {
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(
                                isSelected ? Color.accentColor : Color.gray.opacity(0.2),
                                lineWidth: isSelected ? 2 : 1
                            )
                    )

                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .accentColor : .primary)
            }
            .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .help(icon)
    }
}
