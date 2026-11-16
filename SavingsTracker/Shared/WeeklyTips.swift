import Foundation
import SwiftUI
import UserNotifications

/// One piece of advice shown on the Weekly Tips screen.
struct Tip: Identifiable {
    enum Tone: Int { case warning, good, info, general }

    let id: String
    let tone: Tone
    let symbol: String
    let title: String
    let message: String

    var color: Color {
        switch tone {
        case .warning: .orange
        case .good: .green
        case .info: Theme.accent
        case .general: .yellow
        }
    }
}

/// Builds the weekly tips from the ledger, goals, trackers and the user's profile.
///
/// "This week" is the last 7 days. "Usual" is the weekly average of the 4 weeks before that.
/// Rent, bills and subscriptions are left out of week-to-week comparisons, since they arrive
/// once a month and would otherwise look like spikes.
enum WeeklyTips {
    static let fixedCategories: Set<String> = ["Rent", "Bills", "Subscriptions"]

    struct Week: Identifiable {
        let start: Date
        let spent: Decimal
        var id: Date { start }
    }

    struct Summary {
        /// Day-to-day spending in the last 7 days.
        let thisWeek: Decimal
        /// Average of the weeks before, or nil when there isn't enough history yet.
        let usualWeek: Decimal?
        /// The last 6 weeks, oldest first, ending with this week.
        let weeks: [Week]
    }

    struct Input {
        var income: Decimal
        var savingsPercent: Int
        var payday: Int
        var watched: [String]

        static var current: Input {
            Input(income: Profile.monthlyIncome, savingsPercent: Profile.savingsPercent,
                  payday: Profile.payday, watched: Profile.watched)
        }

        var plannedSavings: Decimal { income * Decimal(savingsPercent) / 100 }
    }

    // MARK: Summary

    private static func variableExpenses(_ entries: [LedgerEntry]) -> [LedgerEntry] {
        entries.filter { $0.kind == .expense && !fixedCategories.contains($0.category) }
    }

    private static func sum(_ entries: [LedgerEntry], from: Date, to: Date) -> Decimal {
        entries.filter { $0.date >= from && $0.date < to }.sum(\.amount)
    }

    /// Number of full weeks of history before this week (0…4).
    private static func historyWeeks(_ entries: [LedgerEntry], weekStart: Date) -> Int {
        guard let first = entries.map(\.date).min(), first < weekStart else { return 0 }
        let days = Calendar.current.dateComponents([.day], from: first, to: weekStart).day ?? 0
        return min(4, days / 7)
    }

    static func summary(_ entries: [LedgerEntry], now: Date = .now) -> Summary {
        let cal = Calendar.current
        let variable = variableExpenses(entries)
        let end = cal.date(byAdding: .second, value: 1, to: now) ?? now
        let weekStart = cal.date(byAdding: .day, value: -7, to: end) ?? end
        let thisWeek = sum(variable, from: weekStart, to: end)

        let history = historyWeeks(entries, weekStart: weekStart)
        var usual: Decimal?
        if history > 0, let from = cal.date(byAdding: .day, value: -7 * history, to: weekStart) {
            usual = sum(variable, from: from, to: weekStart) / Decimal(history)
        }

        let weeks = (0..<6).reversed().compactMap { i -> Week? in
            guard let to = cal.date(byAdding: .day, value: -7 * i, to: end),
                  let from = cal.date(byAdding: .day, value: -7, to: to) else { return nil }
            return Week(start: from, spent: sum(variable, from: from, to: to))
        }
        return Summary(thisWeek: thisWeek, usualWeek: usual, weeks: weeks)
    }

    // MARK: Tips

    static func tips(entries: [LedgerEntry], goals: [SavingsGoal], trackers: [Tracker],
                     input: Input = .current, now: Date = .now) -> [Tip] {
        let cal = Calendar.current
        let summary = summary(entries, now: now)
        let end = cal.date(byAdding: .second, value: 1, to: now) ?? now
        let weekStart = cal.date(byAdding: .day, value: -7, to: end) ?? end
        let variable = variableExpenses(entries)
        let expenses = entries.filter { $0.kind == .expense }
        var tips: [Tip] = []

        // 1. This week compared with a usual week.
        if let usual = summary.usualWeek, usual > 0 {
            let this = summary.thisWeek
            let change = ((this - usual) / usual).double
            let pct = Int((abs(change) * 100).rounded())
            if change > 0.15 {
                tips.append(Tip(id: "week", tone: .warning, symbol: "arrow.up.right",
                                title: "Spending is up this week",
                                message: "You spent \(this.currency) on day-to-day things, \(pct)% more than your usual \(usual.currency) a week."))
            } else if change < -0.10 {
                tips.append(Tip(id: "week", tone: .good, symbol: "arrow.down.right",
                                title: "Nice, spending is down",
                                message: "You spent \(this.currency), \(pct)% less than your usual \(usual.currency). Move the \((usual - this).currency) you didn't spend to a goal before it disappears."))
            } else {
                tips.append(Tip(id: "week", tone: .info, symbol: "equal",
                                title: "A normal week",
                                message: "You spent \(this.currency) on day-to-day things, close to your usual \(usual.currency) a week."))
            }
        } else if summary.thisWeek > 0 {
            tips.append(Tip(id: "week", tone: .info, symbol: "sparkles",
                            title: "Your first week",
                            message: "You spent \(summary.thisWeek.currency) on day-to-day things. After a few more weeks, tips will compare each week with your usual."))
        }

        // 2. Categories that jumped this week.
        let history = historyWeeks(entries, weekStart: weekStart)
        if history > 0, let usualTotal = summary.usualWeek, usualTotal > 0,
           let from = cal.date(byAdding: .day, value: -7 * history, to: weekStart) {
            let thisWeekItems = variable.filter { $0.date >= weekStart && $0.date < end }
            let before = variable.filter { $0.date >= from && $0.date < weekStart }
            let spikes = Set(thisWeekItems.map(\.category)).compactMap { category -> (String, Decimal, Decimal)? in
                let now = thisWeekItems.filter { $0.category == category }.sum(\.amount)
                let usual = before.filter { $0.category == category }.sum(\.amount) / Decimal(history)
                let jumped = usual > 0 ? (now > usual * 1.5) : (now >= usualTotal / 4)
                guard jumped, now - usual >= usualTotal / 10 else { return nil }
                return (category, now, usual)
            }
            for (category, now, usual) in spikes.sorted(by: { $0.1 - $0.2 > $1.1 - $1.2 }).prefix(2) {
                let message = usual > 0
                    ? "\(now.currency) this week, against about \(usual.currency) usually. Back to normal next week saves \((now - usual).currency)."
                    : "\(now.currency) this week, more than you usually spend here. Was it planned?"
                tips.append(Tip(id: "spike-\(category)", tone: .warning, symbol: Categories.symbol(for: category),
                                title: "\(category) jumped", message: message))
            }
        }

        // 3. Savings plan for this month: how much can still be spent per day.
        let monthStart = cal.monthStart(now)
        let planned = input.plannedSavings
        if input.income > 0 {
            let spentThisMonth = expenses.filter { $0.date >= monthStart && $0.date < end }.sum(\.amount)
            // Bills that usually arrive later this month still need room.
            let fixedSoFar = expenses.filter { fixedCategories.contains($0.category) && $0.date >= monthStart && $0.date < end }.sum(\.amount)
            let fixedUsual: Decimal = {
                let months = (1...3).compactMap { cal.date(byAdding: .month, value: -$0, to: monthStart) }
                let totals = months.map { m in
                    expenses.filter { fixedCategories.contains($0.category) && cal.isDate($0.date, equalTo: m, toGranularity: .month) }.sum(\.amount)
                }.filter { $0 > 0 }
                return totals.isEmpty ? 0 : totals.sum { $0 } / Decimal(totals.count)
            }()
            let billsAhead = max(fixedUsual - fixedSoFar, 0)
            let canSpend = input.income - planned
            let left = canSpend - spentThisMonth - billsAhead
            let daysInMonth = cal.range(of: .day, in: .month, for: now)?.count ?? 30
            let daysLeft = max(daysInMonth - cal.component(.day, from: now) + 1, 1)
            if left < 0 {
                tips.append(Tip(id: "plan", tone: .warning, symbol: "exclamationmark.triangle",
                                title: "Behind on this month's savings",
                                message: "To save \(input.savingsPercent)% (\(planned.currency)) this month you can spend \(canSpend.currency). With what you've spent\(billsAhead > 0 ? " and the bills still to come" : ""), you're \((-left).currency) over. A couple of no-spend days will win some back."))
            } else {
                let perDay = (left / Decimal(daysLeft)).rounded(0)
                tips.append(Tip(id: "plan", tone: .good, symbol: "target",
                                title: "Your daily allowance: \(perDay.currency)",
                                message: "Keep day-to-day spending under \(perDay.currency) a day for the next \(daysLeft) day\(daysLeft == 1 ? "" : "s") and you'll save \(planned.currency) this month\(billsAhead > 0 ? ", with room left for your usual bills" : "")."))
            }
        }

        // 4. Payday in the coming week: save first.
        if input.payday > 0, let payday = nextPayday(input.payday, after: now),
           let days = cal.dateComponents([.day], from: cal.startOfDay(for: now), to: payday).day, days <= 7 {
            let when = days == 0 ? "today" : days == 1 ? "tomorrow" : payday.formatted(.dateTime.weekday(.wide))
            let amount = planned > 0 ? "Move \(planned.currency) to savings" : "Move your savings aside"
            tips.append(Tip(id: "payday", tone: .info, symbol: "banknote",
                            title: "Payday is \(when)",
                            message: "\(amount) as soon as it lands. Money you don't see is money you don't spend."))
        }

        // 5. Goals: weekly amount, and whether it fits what's usually left over.
        let open = goals.filter { !$0.isComplete && $0.target > 0 }
        if goals.isEmpty {
            tips.append(Tip(id: "goal-none", tone: .info, symbol: "target",
                            title: "Give your savings a goal",
                            message: "Saving is easier with something to save for. Add a goal, like a trip or a safety net, in Goals."))
        } else if !open.isEmpty {
            let capacity = monthlyLeftover(entries, now: now) ?? (planned > 0 ? planned : nil)
            let dated = open.filter { $0.monthlyNeeded != nil }
            let totalNeeded = dated.compactMap(\.monthlyNeeded).sum { $0 }
            for goal in dated.sorted(by: { ($0.deadline ?? .distantFuture) < ($1.deadline ?? .distantFuture) }).prefix(2) {
                guard let monthly = goal.monthlyNeeded, let deadline = goal.deadline else { continue }
                let weekly = (monthly * 12 / 52).rounded(0)
                let by = deadline.formatted(.dateTime.month(.wide).year())
                if let capacity, capacity > 0, totalNeeded > capacity {
                    let share = capacity * monthly / totalNeeded
                    let months = Int((goal.remaining / share).double.rounded(.up))
                    let realistic = cal.date(byAdding: .month, value: months, to: now) ?? deadline
                    tips.append(Tip(id: "goal-\(goal.name)", tone: .warning, symbol: "calendar.badge.exclamationmark",
                                    title: "\(goal.emoji) \(goal.name) needs more room",
                                    message: "It needs \(monthly.rounded(0).currency) a month to be ready by \(by), but you usually have about \(capacity.rounded(0).currency) left for all your goals. Around \(realistic.formatted(.dateTime.month(.wide).year())) is more realistic, or trim a category to make room."))
                } else {
                    let fits = capacity.map { " That fits in what you usually have left (\($0.rounded(0).currency) a month)." } ?? ""
                    tips.append(Tip(id: "goal-\(goal.name)", tone: .good, symbol: "checkmark.seal",
                                    title: "\(goal.emoji) \(goal.name): \(weekly.currency) a week",
                                    message: "Put aside \(weekly.currency) a week (\(monthly.rounded(0).currency) a month) to reach it by \(by).\(fits)"))
                }
            }
            // A goal without a date: when would it be done with the money that's spare?
            if let goal = open.first(where: { $0.deadline == nil }), let capacity {
                let spare = capacity - totalNeeded
                if spare > 0 {
                    let months = Int((goal.remaining / spare).double.rounded(.up))
                    let date = cal.date(byAdding: .month, value: months, to: now) ?? now
                    tips.append(Tip(id: "goal-open-\(goal.name)", tone: .info, symbol: "hourglass",
                                    title: "\(goal.emoji) \(goal.name) has no date",
                                    message: "With the \(spare.rounded(0).currency) a month you usually have spare, you'd reach it around \(date.formatted(.dateTime.month(.wide).year())). Setting a date makes it easier to stick to."))
                }
            }
        }

        // 6. Categories the user asked to watch, compared with the same point last month.
        let lastMonthStart = cal.date(byAdding: .month, value: -1, to: monthStart) ?? monthStart
        let sameDayLastMonth = cal.date(byAdding: .month, value: -1, to: end) ?? end
        for category in input.watched.prefix(3) {
            let items = expenses.filter { $0.category == category }
            let week = items.filter { $0.date >= weekStart && $0.date < end }.sum(\.amount)
            let month = items.filter { $0.date >= monthStart && $0.date < end }.sum(\.amount)
            let lastMonth = items.filter { $0.date >= lastMonthStart && $0.date < sameDayLastMonth }.sum(\.amount)
            guard month > 0 || lastMonth > 0 else { continue }
            var tone = Tip.Tone.info
            var compare = ""
            if lastMonth > 0 {
                let change = ((month - lastMonth) / lastMonth).double
                if change > 0.1 { tone = .warning; compare = " That's more than by this time last month (\(lastMonth.currency))." }
                else if change < -0.1 { tone = .good; compare = " That's less than by this time last month (\(lastMonth.currency))." }
                else { compare = " About the same as last month." }
            }
            tips.append(Tip(id: "watch-\(category)", tone: tone, symbol: "eye",
                            title: "Watching \(category)",
                            message: "\(week.currency) this week, \(month.currency) so far this month.\(compare)"))
        }

        // 7. Trackers over (or close to) their budget.
        for tracker in trackers {
            guard let budget = tracker.monthlyBudget, budget > 0 else { continue }
            let spent = tracker.spent(inMonthOf: now)
            if spent > budget {
                tips.append(Tip(id: "tracker-\(tracker.name)", tone: .warning, symbol: "gauge.with.needle",
                                title: "\(tracker.emoji) \(tracker.name) is over budget",
                                message: "\(spent.currency) of \(budget.currency) this month. Pausing it until next month keeps the rest of your plan on track."))
            } else if spent >= budget * 0.8 {
                tips.append(Tip(id: "tracker-\(tracker.name)", tone: .info, symbol: "gauge.with.needle",
                                title: "\(tracker.emoji) \(tracker.name) is almost at its budget",
                                message: "\((budget - spent).currency) left of \(budget.currency) for this month."))
            }
        }

        // 8. Small purchases that add up.
        let smallLimit: Decimal? = input.income > 0 ? input.income / 100
            : (summary.usualWeek.map { $0 / 20 }).flatMap { $0 > 0 ? $0 : nil }
        if let smallLimit {
            let small = variable.filter { $0.date >= weekStart && $0.date < end && $0.amount <= smallLimit }
            let total = small.sum(\.amount)
            if small.count >= 5 {
                tips.append(Tip(id: "small", tone: .info, symbol: "cup.and.saucer",
                                title: "Small buys add up",
                                message: "\(small.count) purchases under \(smallLimit.rounded(0).currency) came to \(total.currency) this week. That's about \((total * 52 / 12).rounded(0).currency) a month."))
            }
        }

        // 9. What subscriptions cost in a year.
        if let since = cal.date(byAdding: .day, value: -30, to: end) {
            let monthly = expenses.filter { $0.category == "Subscriptions" && $0.date >= since && $0.date < end }.sum(\.amount)
            if monthly > 0 {
                tips.append(Tip(id: "subs", tone: .info, symbol: "repeat",
                                title: "Subscriptions: \((monthly * 12).rounded(0).currency) a year",
                                message: "You pay about \(monthly.currency) a month. Cancel one you haven't used lately and send the money to a goal."))
            }
        }

        // 10. A general tip that changes every week.
        let week = cal.component(.weekOfYear, from: now)
        let general = generalTips[week % generalTips.count]
        tips.append(Tip(id: "general", tone: .general, symbol: "lightbulb", title: general.0, message: general.1))

        return tips.sorted { $0.tone.rawValue < $1.tone.rawValue }
    }

    /// Average income minus expenses over the last 3 full months that had income logged.
    static func monthlyLeftover(_ entries: [LedgerEntry], now: Date = .now) -> Decimal? {
        let cal = Calendar.current
        let start = cal.monthStart(now)
        let months = (1...3).compactMap { cal.date(byAdding: .month, value: -$0, to: start) }
        let leftovers = months.compactMap { m -> Decimal? in
            let items = entries.filter { cal.isDate($0.date, equalTo: m, toGranularity: .month) }
            let income = items.filter { $0.kind == .income }.sum(\.amount)
            guard income > 0 else { return nil }
            return income - items.filter { $0.kind == .expense }.sum(\.amount)
        }
        guard !leftovers.isEmpty else { return nil }
        return max(leftovers.sum { $0 } / Decimal(leftovers.count), 0)
    }

    static func nextPayday(_ day: Int, after now: Date) -> Date? {
        let cal = Calendar.current
        let today = cal.startOfDay(for: now)
        for offset in 0...1 {
            guard let month = cal.date(byAdding: .month, value: offset, to: cal.monthStart(today)),
                  let days = cal.range(of: .day, in: .month, for: month)?.count,
                  let date = cal.date(byAdding: .day, value: min(day, days) - 1, to: month) else { continue }
            if date >= today { return date }
        }
        return nil
    }

    static let generalTips: [(String, String)] = [
        ("Pay yourself first", "Move your savings on payday, before you spend anything. Saving what's left over rarely works."),
        ("Try the 48-hour rule", "Want something that isn't essential? Wait two days. If you still want it, buy it without guilt."),
        ("Plan one no-spend day", "Pick a day this week with zero spending. It's a small habit that resets how you think about money."),
        ("Shop with a list", "Groceries without a list cost noticeably more. Write it at home, stick to it in the store."),
        ("Round up your savings", "Every time you get paid, round your savings up to the next hundred. You won't miss it."),
        ("Review your subscriptions", "Open your subscriptions once a month and cancel one you didn't use."),
        ("Cook one more meal", "Swapping one delivery a week for cooking at home adds up to a lot over a year."),
        ("Name your savings", "Money saved for a named goal, like \"Trip to Italy\", is much harder to spend on a whim."),
        ("Keep a safety net", "Aim for 3 months of expenses in an emergency fund. It turns surprises into inconveniences."),
        ("Unsubscribe from shop emails", "Fewer sale emails means fewer purchases you didn't plan to make."),
        ("Compare per month, not per week", "A small weekly habit costs 4 times as much each month. Do the math before it becomes routine."),
        ("Celebrate progress", "Hit a goal milestone? Notice it. Seeing progress is what keeps people saving."),
    ]
}

extension Decimal {
    func rounded(_ places: Int) -> Decimal {
        var input = self, output = Decimal()
        NSDecimalRound(&output, &input, places, .plain)
        return output
    }
}

// MARK: - Weekly reminder

/// Schedules the weekly "your tips are ready" notification. Its text stays generic
/// so it's never out of date by the time it arrives.
enum TipsReminder {
    static let id = "weekly-tips"

    /// Asks for permission if needed, then schedules. Returns false if notifications are off.
    @discardableResult
    static func enable(weekday: Int) async -> Bool {
        let center = UNUserNotificationCenter.current()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        guard granted else { return false }
        schedule(weekday: weekday)
        return true
    }

    static func schedule(weekday: Int) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        let content = UNMutableNotificationContent()
        content.title = "Your weekly money tips are ready"
        content.body = "See how this week went and what to tweak for the next one."
        content.sound = .default
        content.userInfo = ["route": "tips"]
        var when = DateComponents()
        when.weekday = weekday
        when.hour = Profile.tipsHour
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }

    static func cancel() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    /// Makes the scheduled reminder match the profile.
    static func sync() {
        if Profile.tipsEnabled { schedule(weekday: Profile.tipsWeekday) } else { cancel() }
    }
}

/// Opens the Weekly Tips screen when the reminder is tapped.
@Observable
final class TipsRouter {
    static let shared = TipsRouter()
    var showTips = false
}

final class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound])
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        if response.notification.request.content.userInfo["route"] as? String == "tips" {
            DispatchQueue.main.async { TipsRouter.shared.showTips = true }
        }
        completionHandler()
    }
}
