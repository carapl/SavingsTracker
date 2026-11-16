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
        ("Groceries", ["tesco", "sainsbury", "asda", "aldi", "lidl", "morrisons", "waitrose", "co-op", "coop", "iceland", "m&s food", "ocado", "linella", "nr.1", "nr1", " nr 1 ", "numarul 1", "kaufland", "fidesco", "velmart", "green hills", "metro", "fourchette"]),
        ("Food", ["mcdonald", "mcd ","kfc", "burger king", "pret", "costa", "starbucks", "greggs", "nando", "deliveroo", "just eat", "uber eats", "subway", "domino", "pizza", "cafe", "restaurant", "glovo", "straus", "andy", "la placinte", "tucano", "bonjour"]),
        ("Transport", ["uber", "bolt", "tfl", "trainline", "national rail", "shell", "bp ", "esso", "parking", "lime", "yandex", "petrom", "lukoil", "rompetrol", "bemol", "avia", "mpay"]),
        ("Subscriptions", ["netflix", "spotify", "disney", "apple.com", "icloud", "youtube", "amazon prime", "now tv", "patreon"]),
        ("Clothes", ["newyorker", "new yorker", "zara", "h&m", "hm moldova", "primark", "lc waikiki", "waikiki", "reserved", "bershka", "pull&bear", "pull and bear", "stradivarius", "massimo dutti", "mango", "sinsay", "cropp", "colin", "defacto", "koton", "nike", "adidas", "puma", "sportmaster", "intersport", "deichmann", "ccc ", "answear", "shein"]),
        ("Shopping", ["amazon", "argos", "ebay", "currys", "ikea", "boots", "darwin", "bomba", "maximum", " enter ", "jysk", "temu", "aliexpress"]),
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
        let byCard = CardMatcher.account(for: rawCard, in: accounts)
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
        var from = entry.account.map { " from \($0.name)" } ?? " (no account matched)"
        // When the card didn't pick the account, say what card name arrived, so it's easy to fix.
        if byCard == nil {
            if rawCard.isEmpty {
                from += " — no card name received from Shortcuts"
            } else {
                UnlinkedCards.add(rawCard)
                from += " — card \"\(rawCard)\" isn't linked yet; link it in Settings › Wallet cards"
            }
        }
        return .result(dialog: "Logged \(value.currency)\(where_) as \(category)\(from).")
    }
}

/// Wallet card names that arrived from Shortcuts but didn't match any account,
/// so Settings can offer to link them.
enum UnlinkedCards {
    static let key = "unlinkedWalletCards"

    static var all: [String] { UserDefaults.standard.stringArray(forKey: key) ?? [] }

    static func add(_ card: String) {
        var list = all
        guard !list.contains(where: { $0.caseInsensitiveCompare(card) == .orderedSame }) else { return }
        list.append(card)
        UserDefaults.standard.set(list, forKey: key)
    }

    static func remove(_ card: String) {
        UserDefaults.standard.set(all.filter { $0 != card }, forKey: key)
    }
}

/// Picks the account whose name best matches a Wallet card name.
/// "MAIB Visa" matches "MAIB UTM" because they share the word "maib".
enum CardMatcher {
    /// Words that appear on lots of cards and say nothing about which bank it is.
    private static let generic: Set<String> = [
        "visa", "mastercard", "master", "card", "cards", "debit", "credit", "classic", "gold",
        "platinum", "business", "virtual", "contactless", "electron", "maestro", "mir", "the", "my",
    ]

    static func words(_ text: String) -> Set<String> {
        let parts = text.lowercased().split { !$0.isLetter && !$0.isNumber }.map(String.init)
        return Set(parts.filter { $0.count >= 2 && !generic.contains($0) })
    }

    static func account(for card: String, in accounts: [Account]) -> Account? {
        let cardName = card.trimmingCharacters(in: .whitespaces).lowercased()
        guard !cardName.isEmpty else { return nil }

        // 0. A card the user linked to an account in Settings.
        if let linked = accounts.first(where: { $0.walletCardList.contains { $0.lowercased() == cardName } }) {
            return linked
        }

        // 1. Whole name contained either way ("MAIB Visa" ⊇ "MAIB").
        if let exact = accounts.first(where: {
            let name = $0.name.lowercased()
            return !name.isEmpty && (cardName.contains(name) || name.contains(cardName))
        }) { return exact }

        // 2. Most shared words ("MAIB Visa" ~ "MAIB UTM"). A tie means it's ambiguous, so no match.
        let cardWords = words(cardName)
        let scored = accounts
            .map { ($0, words($0.name).intersection(cardWords).count) }
            .filter { $0.1 > 0 }
            .sorted { $0.1 > $1.1 }
        guard let best = scored.first else { return nil }
        if scored.count > 1 && scored[1].1 == best.1 { return nil }
        return best.0
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
