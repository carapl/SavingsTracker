#if DEBUG
import Foundation
import SwiftData

/// Fills an empty database with realistic demo data when launched with `-sampleData`.
/// Debug builds only; used for the simulator and README screenshots.
enum SampleData {
    @MainActor
    static func insertIfRequested() {
        guard ProcessInfo.processInfo.arguments.contains("-sampleData") else { return }
        let context = AppData.container.mainContext
        guard (try? context.fetchCount(FetchDescriptor<LedgerEntry>())) == 0 else { return }

        let cal = Calendar.current
        func day(_ monthsAgo: Int, _ day: Int) -> Date {
            let month = cal.date(byAdding: .month, value: -monthsAgo, to: cal.monthStart(.now)) ?? .now
            let date = cal.date(byAdding: .day, value: day - 1, to: month) ?? month
            return min(date, .now)
        }

        let maib = Account(name: "MAIB", kind: .checking, startingBalance: 8_400)
        let mibank = Account(name: "Moldindconbank", kind: .savings, startingBalance: 21_000)
        let cash = Account(name: "Cash", kind: .cash, startingBalance: 3_200)
        maib.isDefaultForAutoLog = true
        [maib, mibank, cash].forEach(context.insert)

        let games = Tracker(name: "Video Games", emoji: "🎮", colorName: "purple", defaultCategory: "Games", monthlyBudget: 600)
        let coffee = Tracker(name: "Coffee", emoji: "☕️", colorName: "orange", defaultCategory: "Food", monthlyBudget: 300)
        [games, coffee].forEach(context.insert)

        func add(_ amount: Decimal, _ kind: TransactionKind, _ category: String, _ note: String,
                 _ date: Date, _ account: Account?, tracker: Tracker? = nil, auto: Bool = false) {
            let e = LedgerEntry(amount: amount, kind: kind, category: category, note: note, date: date)
            context.insert(e)
            e.account = account
            e.tracker = tracker
            e.isAutoLogged = auto
            if auto { e.cardName = "\(account?.name ?? "") Visa" }
        }

        for m in 0..<6 {
            add(18_500 + Decimal(m * 150), .income, "Salary", "Salary", day(m, 5), maib)
            add(4_500, .expense, "Rent", "Rent", day(m, 3), maib)
            add(Decimal(900 + (m * 37) % 300), .expense, "Bills", "Premier Energy", day(m, 12), maib, auto: true)
            add(Decimal(1_400 + (m * 113) % 600), .expense, "Groceries", "Linella", day(m, 8), maib, auto: true)
            add(Decimal(650 + (m * 71) % 400), .expense, "Groceries", "Kaufland", day(m, 19), maib, auto: true)
            add(Decimal(380 + (m * 53) % 250), .expense, "Food", "Glovo", day(m, 15), maib, auto: true)
            add(Decimal(240 + (m * 29) % 120), .expense, "Transport", "Yandex Go", day(m, 10), cash)
            add(Decimal(299 + (m * 97) % 500), .expense, "Games", "Steam", day(m, 14), maib, tracker: games, auto: true)
            add(Decimal(55 + m * 5), .expense, "Food", "Tucano Coffee", day(m, 6), maib, tracker: coffee, auto: true)
            add(Decimal(60 + m * 3), .expense, "Food", "Tucano Coffee", day(m, 17), maib, tracker: coffee, auto: true)
            add(129, .expense, "Subscriptions", "Spotify", day(m, 2), maib, auto: true)
        }
        add(1_299, .expense, "Games", "PlayStation Store", day(0, 4), maib, tracker: games, auto: true)
        add(2_500, .income, "Freelance", "Logo design", day(1, 22), mibank)
        add(1_850, .expense, "Shopping", "Darwin", day(2, 11), maib, auto: true)

        let laptop = SavingsGoal(name: "New Laptop", emoji: "💻", colorName: "blue", target: 25_000,
                                 deadline: cal.date(byAdding: .month, value: 5, to: .now))
        let trip = SavingsGoal(name: "Summer Trip", emoji: "🏖️", colorName: "teal", target: 15_000,
                               deadline: cal.date(byAdding: .month, value: 7, to: .now))
        let emergency = SavingsGoal(name: "Emergency Fund", emoji: "🛟", colorName: "green", target: 30_000, deadline: nil)
        [laptop, trip, emergency].forEach(context.insert)
        for (goal, amounts) in [(laptop, [3_000, 2_500, 3_500, 2_000, 4_000]),
                                (trip, [1_500, 1_000, 2_000]),
                                (emergency, [10_000, 5_000, 4_500, 3_000])] {
            for (i, amount) in amounts.enumerated() {
                let d = GoalDeposit(amount: Decimal(amount), note: "", date: day(amounts.count - 1 - i, 6))
                context.insert(d)
                d.goal = goal
            }
        }

        try? context.save()
    }
}
#endif
