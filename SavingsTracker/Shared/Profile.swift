import Foundation

/// What the user told us about themselves during onboarding (editable in Settings).
/// Stored in UserDefaults so views can bind to it with @AppStorage using these keys.
enum Profile {
    static let onboardedKey = "hasOnboarded"
    static let nameKey = "profileName"
    static let incomeKey = "monthlyIncome"            // Double, 0 = not set
    static let paydayKey = "payday"                   // Int day of month, 0 = varies
    static let savingsPercentKey = "savingsPercent"   // Int
    static let watchedKey = "watchedCategories"       // comma-separated category names
    static let tipsEnabledKey = "weeklyTipsEnabled"   // Bool
    static let tipsWeekdayKey = "weeklyTipsWeekday"   // Int, 1 = Sunday … 7 = Saturday

    static let defaultSavingsPercent = 20
    static let defaultTipsWeekday = 1
    /// Hour of the day the weekly tips reminder arrives.
    static let tipsHour = 18

    private static var store: UserDefaults { .standard }

    static var name: String { store.string(forKey: nameKey) ?? "" }

    static var monthlyIncome: Decimal {
        let value = store.double(forKey: incomeKey)
        return value > 0 ? Decimal(string: String(format: "%.2f", value)) ?? 0 : 0
    }

    static var payday: Int { store.integer(forKey: paydayKey) }

    static var savingsPercent: Int { store.object(forKey: savingsPercentKey) as? Int ?? defaultSavingsPercent }

    static var watched: [String] { decodeList(store.string(forKey: watchedKey) ?? "") }

    static var tipsEnabled: Bool { store.bool(forKey: tipsEnabledKey) }

    static var tipsWeekday: Int { store.object(forKey: tipsWeekdayKey) as? Int ?? defaultTipsWeekday }

    /// Money the user plans to put aside each month (income × savings %).
    static var plannedSavings: Decimal { monthlyIncome * Decimal(savingsPercent) / 100 }

    static func decodeList(_ text: String) -> [String] {
        text.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    static func encodeList(_ list: [String]) -> String { list.joined(separator: ",") }

    // MARK: Backup

    struct Data: Codable {
        var name: String?
        var monthlyIncome: Double?
        var payday: Int?
        var savingsPercent: Int?
        var watched: String?
        var tipsEnabled: Bool?
        var tipsWeekday: Int?
    }

    static func snapshot() -> Data {
        Data(name: name, monthlyIncome: store.double(forKey: incomeKey), payday: payday,
             savingsPercent: savingsPercent, watched: store.string(forKey: watchedKey),
             tipsEnabled: tipsEnabled, tipsWeekday: tipsWeekday)
    }

    static func restore(_ data: Data) {
        if let v = data.name { store.set(v, forKey: nameKey) }
        if let v = data.monthlyIncome { store.set(v, forKey: incomeKey) }
        if let v = data.payday { store.set(v, forKey: paydayKey) }
        if let v = data.savingsPercent { store.set(v, forKey: savingsPercentKey) }
        if let v = data.watched { store.set(v, forKey: watchedKey) }
        if let v = data.tipsEnabled { store.set(v, forKey: tipsEnabledKey) }
        if let v = data.tipsWeekday { store.set(v, forKey: tipsWeekdayKey) }
        TipsReminder.sync()
    }
}
