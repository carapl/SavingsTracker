import SwiftUI

enum Money {
    static let codeKey = "currencyCode"
    static let defaultCode = "MDL"

    /// Currency chosen in Settings (defaults to Moldovan leu), independent of the phone's region.
    static var code: String { UserDefaults.standard.string(forKey: codeKey) ?? defaultCode }

    static var symbol: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        return formatter.currencySymbol ?? code
    }

    static func name(for code: String) -> String {
        Locale.current.localizedString(forCurrencyCode: code) ?? code
    }

    /// Parses what the user typed into a Decimal, honouring their locale's separators.
    static func parse(_ text: String) -> Decimal? {
        var s = text.trimmingCharacters(in: .whitespaces)
        if let group = Locale.current.groupingSeparator, !group.isEmpty {
            s = s.replacingOccurrences(of: group, with: "")
        }
        if let dec = Locale.current.decimalSeparator, dec != "." {
            s = s.replacingOccurrences(of: dec, with: ".")
        }
        guard !s.isEmpty else { return nil }
        return Decimal(string: s, locale: Locale(identifier: "en_US_POSIX"))
    }

    static func editText(_ value: Decimal) -> String {
        value.formatted(.number.grouping(.never).precision(.fractionLength(0...2)))
    }
}

extension Decimal {
    var currency: String { formatted(.currency(code: Money.code)) }
    var double: Double { NSDecimalNumber(decimal: self).doubleValue }
}

extension Sequence {
    func sum(_ value: (Element) -> Decimal) -> Decimal { reduce(0) { $0 + value($1) } }
}

extension Calendar {
    func monthStart(_ date: Date) -> Date { dateInterval(of: .month, for: date)?.start ?? date }

    /// Start dates of the last `count` months, oldest first, ending with the current month.
    func recentMonths(_ count: Int) -> [Date] {
        let current = monthStart(.now)
        return (0..<count).reversed().compactMap { date(byAdding: .month, value: -$0, to: current) }
    }
}

enum Palette {
    static let names = ["blue", "green", "orange", "pink", "purple", "red", "teal", "yellow", "indigo", "mint"]

    static func color(_ name: String) -> Color {
        switch name {
        case "green": .green
        case "orange": .orange
        case "pink": .pink
        case "purple": .purple
        case "red": .red
        case "teal": .teal
        case "yellow": .yellow
        case "indigo": .indigo
        case "mint": .mint
        default: .blue
        }
    }
}

enum Categories {
    static let expense: [(name: String, symbol: String)] = [
        ("Food", "fork.knife"), ("Groceries", "cart"), ("Rent", "house"), ("Bills", "bolt"),
        ("Transport", "car"), ("Clothes", "tshirt"), ("Shopping", "bag"), ("Entertainment", "tv"), ("Games", "gamecontroller"),
        ("Health", "heart"), ("Travel", "airplane"), ("Subscriptions", "repeat"), ("Other", "ellipsis.circle"),
    ]
    static let income: [(name: String, symbol: String)] = [
        ("Salary", "briefcase"), ("Freelance", "laptopcomputer"), ("Gift", "gift"),
        ("Refund", "arrow.uturn.backward"), ("Interest", "percent"), ("Other", "ellipsis.circle"),
    ]

    static func list(for kind: TransactionKind) -> [(name: String, symbol: String)] {
        kind == .income ? income : expense
    }

    static func symbol(for name: String) -> String {
        (expense + income).first { $0.name == name }?.symbol ?? "ellipsis.circle"
    }
}

// MARK: - Reusable views

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardStyle()) }
}

struct EmojiBadge: View {
    let emoji: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(color.opacity(0.2), in: Circle())
    }
}

struct AmountField: View {
    let title: String
    @Binding var text: String
    /// The decimal pad has no minus key, so negative amounts need a fuller keyboard.
    var allowsNegative = false

    var body: some View {
        HStack {
            Text(title)
            Spacer()
            Text(Money.symbol).foregroundStyle(.secondary)
            TextField("0", text: $text)
                .keyboardType(allowsNegative ? .numbersAndPunctuation : .decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(maxWidth: 140)
        }
    }
}

struct ColorChooser: View {
    @Binding var selection: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(Palette.names, id: \.self) { name in
                    Circle()
                        .fill(Palette.color(name))
                        .frame(width: 30, height: 30)
                        .overlay {
                            if name == selection {
                                Image(systemName: "checkmark").font(.caption.bold()).foregroundStyle(.white)
                            }
                        }
                        .onTapGesture { selection = name }
                        .accessibilityLabel(name)
                        .accessibilityAddTraits(name == selection ? .isSelected : [])
                }
            }
            .padding(.vertical, 4)
        }
    }
}

/// Text field that keeps only the last emoji/character typed.
struct EmojiField: View {
    @Binding var emoji: String

    var body: some View {
        HStack {
            Text("Emoji")
            Spacer()
            TextField("🎯", text: $emoji)
                .multilineTextAlignment(.trailing)
                .frame(width: 60)
                .onChange(of: emoji) { _, new in
                    if new.count > 1 { emoji = String(new.suffix(1)) }
                }
        }
    }
}
