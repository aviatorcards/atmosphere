import SwiftUI

struct ColorSwatchPicker: View {
    @Binding var selectedColorHex: String?
    @State private var showCustomPicker = false

    // Curated color palette
    let presetColors: [(name: String, hex: String)] = [
        ("Coral", "#FF6B6B"),
        ("Turquoise", "#4ECDC4"),
        ("Sky Blue", "#45B7D1"),
        ("Salmon", "#FFA07A"),
        ("Mint", "#98D8C8"),
        ("Yellow", "#F7DC6F"),
        ("Lavender", "#BB8FCE"),
        ("Powder Blue", "#85C1E2"),
        ("Peach", "#F8B88B"),
        ("Seafoam", "#A8E6CF"),
        ("Apricot", "#FFD3B6"),
        ("Pink", "#FFAAA5"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Color")
                .font(.headline)

            HStack(spacing: 12) {
                // Preset color swatches
                ForEach(presetColors, id: \.hex) { colorInfo in
                    ColorSwatch(
                        colorHex: colorInfo.hex,
                        name: colorInfo.name,
                        isSelected: selectedColorHex == colorInfo.hex
                    ) {
                        selectedColorHex = colorInfo.hex
                    }
                }

                // Custom color button
                Button(action: { showCustomPicker.toggle() }) {
                    ZStack {
                        Circle()
                            .strokeBorder(Color.gray.opacity(0.3), lineWidth: 2)
                            .background(
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .red, .orange, .yellow, .green, .blue, .purple,
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            )

                        if showCustomPicker {
                            Circle()
                                .strokeBorder(Color.accentColor, lineWidth: 3)
                        }
                    }
                    .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
                .help("Custom color")
            }

            // Custom color picker (shown when custom button is clicked)
            if showCustomPicker {
                ColorPicker(
                    "Custom Color",
                    selection: Binding(
                        get: {
                            if let hex = selectedColorHex {
                                return Color(hex: hex) ?? .accentColor
                            }
                            return .accentColor
                        },
                        set: { newColor in
                            selectedColorHex = newColor.toHex()
                        }
                    )
                )
                .labelsHidden()
                .padding(.top, 4)
            }
        }
    }
}

struct ColorSwatch: View {
    let colorHex: String
    let name: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color(hex: colorHex) ?? .gray)
                    .frame(width: 32, height: 32)

                if isSelected {
                    Circle()
                        .strokeBorder(Color.primary, lineWidth: 3)
                        .frame(width: 32, height: 32)

                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .help(name)
    }
}

// MARK: - Color Extensions

extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a: UInt64
        let r: UInt64
        let g: UInt64
        let b: UInt64
        switch hex.count {
        case 3:  // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:  // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:  // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            return nil
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String {
        guard let components = NSColor(self).cgColor.components, components.count >= 3 else {
            return "#000000"
        }

        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])

        return String(
            format: "#%02lX%02lX%02lX",
            lroundf(r * 255),
            lroundf(g * 255),
            lroundf(b * 255))
    }
}
