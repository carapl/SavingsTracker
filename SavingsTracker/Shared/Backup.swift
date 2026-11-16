import Foundation
import SwiftData

/// Full snapshot of the database. Relationships are stored as indexes into the arrays.
struct BackupFile: Codable {
    var version = 1
    var exportedAt = Date()
    var currency: String
    var accounts: [AccountData]
    var trackers: [TrackerData]
    var goals: [GoalData]
    var entries: [EntryData]

    struct AccountData: Codable {
        var name: String, kind: String, startingBalance: Decimal, createdAt: Date
        var isDefaultForAutoLog: Bool?
    }
    struct TrackerData: Codable {
        var name: String, emoji: String, colorName: String, defaultCategory: String
        var monthlyBudget: Decimal?, createdAt: Date
    }
    struct GoalData: Codable {
        var name: String, emoji: String, colorName: String, target: Decimal
        var deadline: Date?, createdAt: Date, deposits: [DepositData]
    }
    struct DepositData: Codable {
        var amount: Decimal, note: String, date: Date
    }
    struct EntryData: Codable {
        var amount: Decimal, kind: String, category: String, note: String, date: Date
        var isAutoLogged: Bool, account: Int?, tracker: Int?
        var cardName: String?
    }
}

enum Backup {
    /// yyyy-MM-dd in the phone's own time zone (ISO 8601 formatting would use UTC and shift late-night dates).
    private static func day(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }
    private static var stamp: String { day(.now) }

    // MARK: Export

    static func makeBackup(_ context: ModelContext) throws -> URL {
        let accounts = try context.fetch(FetchDescriptor<Account>(sortBy: [SortDescriptor(\.createdAt)]))
        let trackers = try context.fetch(FetchDescriptor<Tracker>(sortBy: [SortDescriptor(\.createdAt)]))
        let goals = try context.fetch(FetchDescriptor<SavingsGoal>(sortBy: [SortDescriptor(\.createdAt)]))
        let entries = try context.fetch(FetchDescriptor<LedgerEntry>(sortBy: [SortDescriptor(\.date)]))

        let file = BackupFile(
            currency: Money.code,
            accounts: accounts.map { .init(name: $0.name, kind: $0.kindRaw, startingBalance: $0.startingBalance, createdAt: $0.createdAt, isDefaultForAutoLog: $0.isDefaultForAutoLog) },
            trackers: trackers.map { .init(name: $0.name, emoji: $0.emoji, colorName: $0.colorName,
                                           defaultCategory: $0.defaultCategory, monthlyBudget: $0.monthlyBudget, createdAt: $0.createdAt) },
            goals: goals.map { goal in
                .init(name: goal.name, emoji: goal.emoji, colorName: goal.colorName, target: goal.target,
                      deadline: goal.deadline, createdAt: goal.createdAt,
                      deposits: (goal.deposits ?? []).map { .init(amount: $0.amount, note: $0.note, date: $0.date) })
            },
            entries: entries.map { entry in
                .init(amount: entry.amount, kind: entry.kindRaw, category: entry.category, note: entry.note,
                      date: entry.date, isAutoLogged: entry.isAutoLogged,
                      account: entry.account.flatMap { a in accounts.firstIndex { $0 === a } },
                      tracker: entry.tracker.flatMap { t in trackers.firstIndex { $0 === t } },
                      cardName: entry.cardName)
            }
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try write(encoder.encode(file), name: "Savings Backup \(stamp).json")
    }

    static func makeCSV(_ context: ModelContext) throws -> URL {
        let entries = try context.fetch(FetchDescriptor<LedgerEntry>(sortBy: [SortDescriptor(\.date, order: .reverse)]))
        var lines = ["Date,Type,Amount,Currency,Category,Note,Account,Tracker,Logged automatically"]
        for e in entries {
            let fields = [
                day(e.date),
                e.kind.label,
                "\(e.signedAmount)",
                Money.code,
                e.category,
                e.note,
                e.account?.name ?? "",
                e.tracker?.name ?? "",
                e.isAutoLogged ? "Yes" : "No",
            ]
            lines.append(fields.map(csvField).joined(separator: ","))
        }
        // Byte-order mark so Excel reads letters like ă, ș, ț correctly.
        let data = Data("\u{FEFF}".utf8) + Data(lines.joined(separator: "\r\n").utf8)
        return try write(data, name: "Savings Transactions \(stamp).csv")
    }

    private static func csvField(_ value: String) -> String {
        guard value.contains(where: { ",\"\n\r".contains($0) }) else { return value }
        return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private static func write(_ data: Data, name: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    // MARK: Restore

    static func read(_ url: URL) throws -> BackupFile {
        let accessing = url.startAccessingSecurityScopedResource()
        defer { if accessing { url.stopAccessingSecurityScopedResource() } }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(BackupFile.self, from: Data(contentsOf: url))
    }

    /// Replaces everything in the database with the backup's contents.
    static func restore(_ file: BackupFile, into context: ModelContext) throws {
        try context.delete(model: LedgerEntry.self)
        try context.delete(model: GoalDeposit.self)
        try context.delete(model: SavingsGoal.self)
        try context.delete(model: Tracker.self)
        try context.delete(model: Account.self)

        let accounts = file.accounts.map { a -> Account in
            let account = Account(name: a.name, kind: AccountKind(rawValue: a.kind) ?? .other, startingBalance: a.startingBalance)
            account.createdAt = a.createdAt
            account.isDefaultForAutoLog = a.isDefaultForAutoLog ?? false
            context.insert(account)
            return account
        }
        let trackers = file.trackers.map { t -> Tracker in
            let tracker = Tracker(name: t.name, emoji: t.emoji, colorName: t.colorName,
                                  defaultCategory: t.defaultCategory, monthlyBudget: t.monthlyBudget)
            tracker.createdAt = t.createdAt
            context.insert(tracker)
            return tracker
        }
        for g in file.goals {
            let goal = SavingsGoal(name: g.name, emoji: g.emoji, colorName: g.colorName, target: g.target, deadline: g.deadline)
            goal.createdAt = g.createdAt
            context.insert(goal)
            for d in g.deposits {
                let deposit = GoalDeposit(amount: d.amount, note: d.note, date: d.date)
                context.insert(deposit)
                deposit.goal = goal
            }
        }
        for e in file.entries {
            let entry = LedgerEntry(amount: e.amount, kind: TransactionKind(rawValue: e.kind) ?? .expense,
                                    category: e.category, note: e.note, date: e.date)
            entry.isAutoLogged = e.isAutoLogged
            entry.cardName = e.cardName ?? ""
            context.insert(entry)
            if let i = e.account, accounts.indices.contains(i) { entry.account = accounts[i] }
            if let i = e.tracker, trackers.indices.contains(i) { entry.tracker = trackers[i] }
        }

        UserDefaults.standard.set(file.currency, forKey: Money.codeKey)
        try context.save()
    }
}
