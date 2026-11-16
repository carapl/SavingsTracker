import Foundation
import SwiftData
import AppIntents

/// One shared database, used by both the app UI and Shortcuts actions.
enum AppData {
    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: Account.self, LedgerEntry.self, Tracker.self, SavingsGoal.self, GoalDeposit.self)
        } catch {
            fatalError("Could not open the database: \(error)")
        }
    }()
}

/// Guesses a category from a merchant name. Matching is case-insensitive and by substring.
enum MerchantRules {
    static let keywords: [(category: String, words: [String])] = [
        ("Games", ["steam", "playstation", "psn", "xbox", "nintendo", "epic games", "riot", "blizzard", "game", "cex"]),
        ("Groceries", ["tesco", "sainsbury", "asda", "aldi", "lidl", "morrisons", "waitrose", "co-op", "coop", "iceland", "m&s food", "ocado", "linella", "nr.1", "nr1", "kaufland", "fidesco", "velmart", "green hills", "metro", "fourchette"]),
        ("Food", ["mcdonald", "kfc", "burger king", "pret", "costa", "starbucks", "greggs", "nando", "deliveroo", "just eat", "uber eats", "subway", "domino", "pizza", "cafe", "restaurant", "glovo", "straus", "andy", "la placinte", "tucano", "bonjour"]),
        ("Transport", ["uber", "bolt", "tfl", "trainline", "national rail", "shell", "bp ", "esso", "parking", "lime", "yandex", "petrom", "lukoil", "rompetrol", "bemol", "avia", "mpay"]),
        ("Subscriptions", ["netflix", "spotify", "disney", "apple.com", "icloud", "youtube", "amazon prime", "now tv", "patreon"]),
        ("Shopping", ["amazon", "argos", "ebay", "primark", "zara", "h&m", "currys", "ikea", "boots", "darwin", "bomba", "maximum", " enter ", "jysk", "temu", "aliexpress"]),
        ("Entertainment", ["cinema", "odeon", "vue", "cineworld", "ticketmaster"]),
        ("Health", ["pharmacy", "superdrug", "gym", "puregym", "the gym", "farmacia", "felicia", "familiei", "hippocrates"]),
        ("Bills", ["octopus", "british gas", "edf", "vodafone", "ee ", "o2", "three", "virgin media", "bt ", "orange", "moldcell", "moldtelecom", "starnet", "premier energy", "moldovagaz", "apa-canal"]),
        ("Travel", ["ryanair", "easyjet", "british airways", "booking.com", "airbnb", "hotel", "fly one", "hisky", "wizz"]),
    ]

    static func category(for merchant: String) -> String {
        let name = " \(merchant.lowercased()) "
        return keywords.first { rule in rule.words.contains { name.contains($0) } }?.category ?? "Other"
    }
}

struct LogExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Log Expense"
    static let description = IntentDescription("Saves a purchase in Savings. Use it with a Wallet \"Transaction\" automation to log card payments automatically.")
    static let openAppWhenRun = false

    @Parameter(title: "Amount")
    var amount: Double

    @Parameter(title: "Merchant", requestValueDialog: "Where did you pay?")
    var merchant: String

    @Parameter(title: "Card")
    var card: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$amount) at \(\.$merchant)") {
            \.$card
        }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        let value = Decimal(abs(amount)).rounded(2)
        guard value > 0 else { return .result(dialog: "Nothing logged: the amount was zero.") }

        let context = AppData.container.mainContext
        let place = merchant.trimmingCharacters(in: .whitespaces)
        let category = MerchantRules.category(for: place)

        let rawCard = (card ?? "").trimmingCharacters(in: .whitespaces)
        let entry = LedgerEntry(amount: value, kind: .expense, category: category, note: place)
        entry.isAutoLogged = true
        entry.cardName = rawCard
        context.insert(entry)

        // Link to an account whose name matches the card ("MAIB Visa" -> account "MAIB"),
        // otherwise the default account from Settings, otherwise the only account if there is just one.
        let accounts = try context.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.createdAt)]))
        let cardName = rawCard.lowercased()
        let byCard = cardName.isEmpty ? nil : accounts.first {
            let name = $0.name.lowercased()
            return !name.isEmpty && (cardName.contains(name) || name.contains(cardName))
        }
        entry.account = byCard
            ?? accounts.first { $0.isDefaultForAutoLog }
            ?? (accounts.count == 1 ? accounts.first : nil)

        // Put it in the first tracker that uses this category, e.g. Steam -> 🎮 Video Games.
        if category != "Other" {
            let trackers = try context.fetch(FetchDescriptor<Tracker>(sortBy: [SortDescriptor(\.createdAt)]))
            entry.tracker = trackers.first { $0.defaultCategory == category }
        }

        try context.save()
        let where_ = place.isEmpty ? "" : " at \(place)"
        let from = entry.account.map { " from \($0.name)" } ?? " (no account matched)"
        return .result(dialog: "Logged \(value.currency)\(where_) as \(category)\(from).")
    }
}

struct SavingsShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogExpenseIntent(),
            phrases: ["Log an expense in \(.applicationName)", "Add a purchase to \(.applicationName)"],
            shortTitle: "Log Expense",
            systemImageName: "creditcard"
        )
    }
}

private extension Decimal {
    func rounded(_ places: Int) -> Decimal {
        var input = self, output = Decimal()
        NSDecimalRound(&output, &input, places, .plain)
        return output
    }
}
