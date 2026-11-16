import SwiftUI
import UIKit

private struct ShowSettingsKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    /// Opens the Settings sheet owned by ContentView.
    var showSettings: () -> Void {
        get { self[ShowSettingsKey.self] }
        set { self[ShowSettingsKey.self] = newValue }
    }
}

enum Theme {
    static let appearanceKey = "appearance"
    static let accentKey = "accent"

    enum Appearance: String, CaseIterable, Identifiable {
        case system, light, dark
        var id: Self { self }
        var label: String {
            switch self {
            case .system: "Automatic"
            case .light: "Light"
            case .dark: "Dark"
            }
        }
        var symbol: String {
            switch self {
            case .system: "circle.lefthalf.filled"
            case .light: "sun.max.fill"
            case .dark: "moon.fill"
            }
        }
        var colorScheme: ColorScheme? {
            switch self {
            case .system: nil
            case .light: .light
            case .dark: .dark
            }
        }
    }

    static let accents: [(id: String, color: Color)] = [
        ("default", Color("AccentColor")), ("blue", .blue), ("indigo", .indigo), ("purple", .purple),
        ("pink", .pink), ("red", .red), ("orange", .orange), ("yellow", .yellow), ("teal", .teal),
    ]

    static func accent(_ id: String) -> Color {
        accents.first { $0.id == id }?.color ?? Color("AccentColor")
    }

    /// The accent picked in Settings. Screens redraw when it changes because ContentView rebuilds.
    static var accent: Color { accent(UserDefaults.standard.string(forKey: accentKey) ?? "default") }

    // MARK: App icons

    struct AppIconOption: Identifiable {
        let id: String
        let label: String
        /// nil means the primary icon.
        let iconName: String?
        var preview: String { "IconPreview-\(id)" }
    }

    static let icons: [AppIconOption] = [
        .init(id: "Green", label: "Green", iconName: nil),
        .init(id: "Midnight", label: "Midnight", iconName: "AppIcon-Midnight"),
        .init(id: "Purple", label: "Purple", iconName: "AppIcon-Purple"),
        .init(id: "Sunset", label: "Sunset", iconName: "AppIcon-Sunset"),
    ]
}

/// Grid of selectable accent color swatches.
struct AccentChooser: View {
    @Binding var selection: String

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 14) {
            ForEach(Theme.accents, id: \.id) { item in
                Circle()
                    .fill(item.color.gradient)
                    .frame(width: 38, height: 38)
                    .overlay {
                        if item.id == selection {
                            Image(systemName: "checkmark").font(.footnote.bold()).foregroundStyle(.white)
                        }
                    }
                    .overlay(Circle().strokeBorder(.primary.opacity(item.id == selection ? 0.25 : 0), lineWidth: 3).padding(-5))
                    .onTapGesture { selection = item.id }
                    .accessibilityLabel(item.id == "default" ? "Default green" : item.id.capitalized)
                    .accessibilityAddTraits(item.id == selection ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }
}

/// Row of app icon choices; switching calls UIKit's alternate icon API.
struct AppIconChooser: View {
    @State private var current = UIApplication.shared.alternateIconName
    @State private var error: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 14) {
                ForEach(Theme.icons) { icon in
                    let selected = icon.iconName == current
                    Button {
                        guard !selected else { return }
                        UIApplication.shared.setAlternateIconName(icon.iconName) { err in
                            Task { @MainActor in
                                if let err { error = err.localizedDescription } else { current = icon.iconName }
                            }
                        }
                    } label: {
                        VStack(spacing: 6) {
                            Image(icon.preview)
                                .resizable()
                                .frame(width: 58, height: 58)
                                .clipShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                                        .strokeBorder(Color.primary.opacity(selected ? 0.3 : 0), lineWidth: 3)
                                        .padding(-5)
                                )
                            Text(icon.label).font(.caption).foregroundStyle(selected ? .primary : .secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            if let error { Text(error).font(.caption).foregroundStyle(.red) }
        }
        .padding(.vertical, 6)
    }
}
