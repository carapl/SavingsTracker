import Foundation
import SwiftData

// All models follow CloudKit's rules (every property has a default,
// relationships are optional, no unique constraints), so iCloud sync
// can be switched on later without migrating data.

enum TransactionKind: String, Codable, CaseIterable, Identifiable {
    case expense, income
    var id: Self { self }
    var label: String { self == .income ? "Income" : "Expense" }
}

enum AccountKind: String, Codable, CaseIterable, Identifiable {
    case checking, savings, cash, credit, investment, other
    var id: Self { self }
    var label: String { rawValue.capitalized }
    var symbol: String {
        switch self {
        case .checking: "building.columns"
        case .savings: "banknote"
        case .cash: "dollarsign.circle"
        case .credit: "creditcard"
        case .investment: "chart.line.uptrend.xyaxis"
        case .other: "tray"
        }
    }
}

// MARK: - Account

@Model
final class Account {
    var name: String = ""
    var kindRaw: String = AccountKind.checking.rawValue
    /// Balance before any transactions linked to this account.
    var startingBalance: Decimal = 0
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \LedgerEntry.account)
    var entries: [LedgerEntry]? = []

    init(name: String, kind: AccountKind, startingBalance: Decimal) {
        self.name = name
        self.kindRaw = kind.rawValue
        self.startingBalance = startingBalance
    }

    var kind: AccountKind {
        get { AccountKind(rawValue: kindRaw) ?? .other }
        set { kindRaw = newValue.rawValue }
    }

    var linkedNet: Decimal { (entries ?? []).sum(\.signedAmount) }
    var balance: Decimal { startingBalance + linkedNet }
}

// MARK: - Income / expense entry

@Model
final class LedgerEntry {
    /// Always positive; `kind` decides the direction.
    var amount: Decimal = 0
    var kindRaw: String = TransactionKind.expense.rawValue
    var category: String = "Other"
    var note: String = ""
    var date: Date = Date()
    /// True when saved by the Shortcuts automation rather than typed in.
    var isAutoLogged: Bool = false
    var account: Account?
    var tracker: Tracker?

    init(amount: Decimal, kind: TransactionKind, category: String, note: String = "", date: Date = .now) {
        self.amount = amount
        self.kindRaw = kind.rawValue
        self.category = category
        self.note = note
        self.date = date
    }

    var kind: TransactionKind {
        get { TransactionKind(rawValue: kindRaw) ?? .expense }
        set { kindRaw = newValue.rawValue }
    }

    var signedAmount: Decimal { kind == .income ? amount : -amount }
}

// MARK: - Custom trackers (e.g. "Video Games")

@Model
final class Tracker {
    var name: String = ""
    var emoji: String = "🎮"
    var colorName: String = "purple"
    var defaultCategory: String = "Other"
    var monthlyBudget: Decimal?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .nullify, inverse: \LedgerEntry.tracker)
    var entries: [LedgerEntry]? = []

    init(name: String, emoji: String, colorName: String, defaultCategory: String, monthlyBudget: Decimal?) {
        self.name = name
        self.emoji = emoji
        self.colorName = colorName
        self.defaultCategory = defaultCategory
        self.monthlyBudget = monthlyBudget
    }

    var sortedEntries: [LedgerEntry] { (entries ?? []).sorted { $0.date > $1.date } }
    var expenses: [LedgerEntry] { (entries ?? []).filter { $0.kind == .expense } }
    var totalSpent: Decimal { expenses.sum(\.amount) }

    func spent(inMonthOf date: Date = .now) -> Decimal {
        expenses
            .filter { Calendar.current.isDate($0.date, equalTo: date, toGranularity: .month) }
            .sum(\.amount)
    }
}

// MARK: - Savings goals

@Model
final class SavingsGoal {
    var name: String = ""
    var emoji: String = "🎯"
    var colorName: String = "blue"
    var target: Decimal = 0
    var deadline: Date?
    var createdAt: Date = Date()

    @Relationship(deleteRule: .cascade, inverse: \GoalDeposit.goal)
    var deposits: [GoalDeposit]? = []

    init(name: String, emoji: String, colorName: String, target: Decimal, deadline: Date?) {
        self.name = name
        self.emoji = emoji
        self.colorName = colorName
        self.target = target
        self.deadline = deadline
    }

    var sortedDeposits: [GoalDeposit] { (deposits ?? []).sorted { $0.date > $1.date } }
    var saved: Decimal { (deposits ?? []).sum(\.amount) }
    var remaining: Decimal { max(target - saved, 0) }
    var isComplete: Bool { target > 0 && saved >= target }
    var progress: Double {
        guard target > 0 else { return 0 }
        return min(max(saved.double / target.double, 0), 1)
    }

    /// How much to put away each month to hit the deadline.
    var monthlyNeeded: Decimal? {
        guard let deadline, remaining > 0 else { return nil }
        let months = Calendar.current.dateComponents([.month], from: .now, to: deadline).month ?? 0
        return remaining / Decimal(max(months, 1))
    }
}

@Model
final class GoalDeposit {
    /// Positive for money added, negative for withdrawals.
    var amount: Decimal = 0
    var note: String = ""
    var date: Date = Date()
    var goal: SavingsGoal?

    init(amount: Decimal, note: String = "", date: Date = .now) {
        self.amount = amount
        self.note = note
        self.date = date
    }
}
