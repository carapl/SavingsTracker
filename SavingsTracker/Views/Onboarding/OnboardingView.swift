import SwiftUI
import SwiftData

/// First-launch intro: what the app does, how to use it, then a short setup
/// (profile, saving plan, first account, first goal, weekly tips).
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query private var goals: [SavingsGoal]
    @AppStorage(Money.codeKey) private var currency = Money.defaultCode
    @AppStorage(Profile.onboardedKey) private var onboarded = false

    enum Step: Int, CaseIterable {
        case welcome, features, howTo, aboutYou, plan, account, goal, tips, done
    }

    @State private var step = OnboardingView.initialStep

    /// Debug builds accept `-onboardingStep N` at launch, for checking each page.
    private static var initialStep: Step {
        // Set once from the advanced tools to open the intro at a given page.
        let store = UserDefaults.standard
        if let n = store.object(forKey: startStepKey) as? Int {
            store.removeObject(forKey: startStepKey)
            if let step = Step(rawValue: n) { return step }
        }
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-onboardingStep"), i + 1 < args.count,
           let n = Int(args[i + 1]), let step = Step(rawValue: n) { return step }
        #endif
        return .welcome
    }
    @State private var forward = true
    static let startStepKey = "onboardingStartStep"

    // About you
    @State private var name = Profile.name
    @State private var incomeText = Profile.monthlyIncome > 0 ? Money.editText(Profile.monthlyIncome) : ""
    @State private var payday = Profile.payday
    // Saving plan
    @State private var percent = Double(Profile.savingsPercent)
    @State private var watched = Set(Profile.watched)
    // First account
    @State private var accountName = ""
    @State private var accountKind = AccountKind.checking
    @State private var balanceText = ""
    // First goal
    @State private var goalEmoji = "💻"
    @State private var goalName = ""
    @State private var goalTargetText = ""
    @State private var hasDeadline = true
    @State private var deadline = Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now
    // Weekly tips
    @State private var tipsOn = true
    @State private var weekday = Profile.tipsWeekday

    private var income: Decimal { Money.parse(incomeText).map { max($0, 0) } ?? 0 }
    private var planned: Decimal { income * Decimal(Int(percent)) / 100 }
    private var goalTarget: Decimal { Money.parse(goalTargetText).map { max($0, 0) } ?? 0 }
    private var trimmedAccount: String { accountName.trimmingCharacters(in: .whitespaces) }
    private var trimmedGoal: String { goalName.trimmingCharacters(in: .whitespaces) }
    private var addsGoal: Bool { !trimmedGoal.isEmpty && goalTarget > 0 }

    var body: some View {
        VStack(spacing: 0) {
            header
            ZStack {
                page(step)
                    .id(step)
                    .transition(.asymmetric(
                        insertion: .move(edge: forward ? .trailing : .leading).combined(with: .opacity),
                        removal: .move(edge: forward ? .leading : .trailing).combined(with: .opacity)))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            footer
        }
        .background(Color(.systemGroupedBackground))
        .sensoryFeedback(.selection, trigger: step)
    }

    // MARK: Chrome

    private var header: some View {
        HStack(spacing: 16) {
            Button { go(-1) } label: {
                Image(systemName: "chevron.left").font(.body.weight(.semibold))
                    .frame(width: 36, height: 36)
                    .background(Color(.secondarySystemGroupedBackground), in: Circle())
            }
            .opacity(step == .welcome || step == .done ? 0 : 1)
            .disabled(step == .welcome || step == .done)
            .accessibilityLabel("Back")

            ProgressView(value: Double(step.rawValue), total: Double(Step.allCases.count - 1))
                .tint(Theme.accent)
                .animation(Motion.change, value: step)

            Button("Skip") { jump(to: .aboutYou) }
                .font(.subheadline)
                .opacity(step.rawValue < Step.aboutYou.rawValue && step != .welcome ? 1 : 0)
                .disabled(!(step.rawValue < Step.aboutYou.rawValue && step != .welcome))
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .frame(height: 52)
    }

    private var footer: some View {
        VStack(spacing: 10) {
            Button(action: primaryAction) {
                Text(primaryTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .buttonBorderShape(.capsule)
            .contentTransition(.opacity)
            .animation(Motion.change, value: primaryTitle)

            if step == .account || step == .goal {
                Button("Skip for now") { go(1) }
                    .font(.subheadline)
                    .opacity(isStepFilled ? 1 : 0)
                    .disabled(!isStepFilled)
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
        .padding(.top, 8)
    }

    private var isStepFilled: Bool {
        switch step {
        case .account: !trimmedAccount.isEmpty
        case .goal: addsGoal
        default: false
        }
    }

    private var primaryTitle: String {
        switch step {
        case .welcome: "Get started"
        case .account: trimmedAccount.isEmpty ? "Skip" : "Add account"
        case .goal: addsGoal ? "Add goal" : "Skip"
        case .done: "Start using Savings"
        default: "Continue"
        }
    }

    private func primaryAction() {
        if step == .done { finish() } else { go(1) }
    }

    private func go(_ delta: Int) {
        guard let next = Step(rawValue: step.rawValue + delta) else { return }
        jump(to: next)
    }

    private func jump(to next: Step) {
        hideKeyboard()
        forward = next.rawValue > step.rawValue
        withAnimation(Motion.entrance) { step = next }
    }

    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: Pages

    @ViewBuilder
    private func page(_ step: Step) -> some View {
        switch step {
        case .welcome: welcome
        case .features: features
        case .howTo: howTo
        case .aboutYou: aboutYou
        case .plan: plan
        case .account: account
        case .goal: goal
        case .tips: tips
        case .done: done
        }
    }

    private var welcome: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("IconPreview-Green")
                .resizable()
                .frame(width: 112, height: 112)
                .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
                .shadow(color: .green.opacity(0.35), radius: 24, y: 10)
                .reveal(0)
            VStack(spacing: 10) {
                Text("Welcome to Savings").font(.largeTitle.bold())
                Text("See where your money goes, spend with a plan and save for the things you want.")
                    .font(.title3).foregroundStyle(.secondary)
            }
            .multilineTextAlignment(.center)
            .reveal(1)
            Text("Setup takes about a minute.")
                .font(.subheadline).foregroundStyle(.tertiary)
                .reveal(2)
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 32)
    }

    private var features: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageTitle("Everything in one place", "Five tabs, each with one job.")
                let items: [(String, Color, String, String)] = [
                    ("chart.pie.fill", .green, "Overview", "Your balance, this month and where the money went."),
                    ("list.bullet", .blue, "Activity", "Every transaction, grouped by month, with search."),
                    ("target", .red, "Goals", "Save for a laptop, a trip or a safety net, and see the progress."),
                    ("square.grid.2x2.fill", .purple, "Trackers", "Keep an eye on things like games or coffee, with a monthly budget."),
                    ("building.columns.fill", .teal, "Accounts", "All your cards and cash, with balances that update themselves."),
                    ("bolt.fill", .orange, "Apple Pay, automatically", "Card payments log themselves, with the right category."),
                    ("lightbulb.fill", .yellow, "Weekly tips", "How your week went and what to tweak, every week."),
                ]
                ForEach(Array(items.enumerated()), id: \.offset) { i, item in
                    FeatureRow(symbol: item.0, color: item.1, title: item.2, text: item.3).reveal(i + 1)
                }
            }
            .padding(24)
        }
    }

    private var howTo: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageTitle("How to add things", "The basics, in four steps.")
                StepRow(number: 1, title: "Tap + to log spending or income",
                        text: "On Overview or Activity. Pick a category and the account it came from.").reveal(1)
                StepRow(number: 2, title: "Or let Apple Pay do it",
                        text: "Set up a Shortcuts automation once and card payments appear on their own, marked with ⚡.").reveal(2)
                StepRow(number: 3, title: "Put money into your goals",
                        text: "Open a goal and tap Add money whenever you save something.").reveal(3)
                StepRow(number: 4, title: "Check your weekly tips",
                        text: "On Overview, or when the weekly reminder arrives.").reveal(4)

                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Open **Shortcuts** › **Automation** › **+**")
                        Text("2. Choose **Wallet** (Transaction) › **Any card**, and **Run Immediately**")
                        Text("3. Add the **Log Expense** action from Savings")
                        Text("4. Set **Amount** to *Amount*, **Merchant** to *Merchant* and **Card** to *Card or Pass*")
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
                } label: {
                    Label("Set up Apple Pay logging", systemImage: "bolt.fill").font(.subheadline.weight(.semibold))
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .reveal(5)
            }
            .padding(24)
        }
    }

    private var aboutYou: some View {
        Form {
            Section {
                EmptyView()
            } header: {
                PageTitle("About you", "Used for your saving plan and tips. It stays on this phone.")
                    .textCase(nil).foregroundStyle(.primary)
                    .padding(.horizontal, -20)
            }
            Section("Name") {
                TextField("What should we call you?", text: $name)
                    .textContentType(.givenName)
            }
            Section {
                CurrencyPicker(selection: $currency)
                AmountField(title: "Monthly income", text: $incomeText)
                Picker("Payday", selection: $payday) {
                    Text("Varies").tag(0)
                    ForEach(1...31, id: \.self) { Text(ordinal($0)).tag($0) }
                }
            } header: {
                Text("Money in")
            } footer: {
                Text("Roughly is fine, after tax. You can change it later in Settings.")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var plan: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageTitle("Your saving plan", "How much of your income do you want to put aside?")
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        CountingText.percent(percent).font(.system(size: 48, weight: .bold, design: .rounded))
                            .animation(Motion.change, value: percent)
                        Spacer()
                        if income > 0 {
                            VStack(alignment: .trailing, spacing: 2) {
                                AmountText(planned).font(.headline).monospacedDigit()
                                Text("a month · \((planned * 12 / 52).rounded(0).currency) a week")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                    Slider(value: $percent, in: 5...50, step: 5)
                    HStack {
                        ForEach([10, 20, 30], id: \.self) { p in
                            Button("\(p)%") { withAnimation(Motion.change) { percent = Double(p) } }
                                .buttonStyle(.bordered)
                                .tint(Int(percent) == p ? Theme.accent : .secondary)
                        }
                    }
                    Text(income > 0 ? "A common rule is 20%. Start lower if it's tight; you can raise it later."
                                    : "Add your income on the previous step to see this in money.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                .card()

                VStack(alignment: .leading, spacing: 12) {
                    Text("Keep an eye on").font(.headline)
                    Text("Pick categories you tend to overspend on. Weekly tips will tell you how they're going.")
                        .font(.footnote).foregroundStyle(.secondary)
                    FlowLayout(spacing: 8) {
                        ForEach(Categories.expense.map(\.name).filter { !["Other", "Rent"].contains($0) }, id: \.self) { name in
                            let on = watched.contains(name)
                            Button {
                                withAnimation(Motion.change) { if on { watched.remove(name) } else { watched.insert(name) } }
                            } label: {
                                Label(name, systemImage: Categories.symbol(for: name))
                                    .font(.subheadline)
                                    .padding(.horizontal, 12).padding(.vertical, 8)
                                    .background(on ? Theme.accent.opacity(0.18) : Color(.tertiarySystemFill), in: Capsule())
                                    .overlay(Capsule().strokeBorder(on ? Theme.accent : .clear, lineWidth: 1.5))
                                    .foregroundStyle(on ? Theme.accent : .primary)
                            }
                            .buttonStyle(PressableStyle())
                            .accessibilityAddTraits(on ? .isSelected : [])
                        }
                    }
                }
                .card()
            }
            .padding(24)
        }
    }

    private var account: some View {
        Form {
            Section {
                EmptyView()
            } header: {
                PageTitle("Your first account", accounts.isEmpty
                          ? "A card or cash: where your money is. Balances update as you log things."
                          : "You already have \(accounts.count) account\(accounts.count == 1 ? "" : "s"), so you can skip this.")
                    .textCase(nil).foregroundStyle(.primary)
                    .padding(.horizontal, -20)
            }
            Section {
                TextField("Name, e.g. MAIB", text: $accountName)
                Picker("Type", selection: $accountKind) {
                    ForEach(AccountKind.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                }
                AmountField(title: "Balance now", text: $balanceText, allowsNegative: true)
            } footer: {
                Text("Name it like your bank card (for example MAIB) and Apple Pay payments will land here automatically.")
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var goal: some View {
        Form {
            Section {
                EmptyView()
            } header: {
                PageTitle("Something to save for?", "A wish, a trip, a safety net. Saving is easier with a goal.")
                    .textCase(nil).foregroundStyle(.primary)
                    .padding(.horizontal, -20)
            }
            Section {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(["💻", "✈️", "🏖️", "🚗", "🏠", "📱", "🎮", "🛟", "🎁", "🎓"], id: \.self) { e in
                            Text(e).font(.title2)
                                .frame(width: 46, height: 46)
                                .background(goalEmoji == e ? Theme.accent.opacity(0.2) : Color(.tertiarySystemFill), in: Circle())
                                .overlay(Circle().strokeBorder(goalEmoji == e ? Theme.accent : .clear, lineWidth: 2))
                                .scaleEffect(goalEmoji == e ? 1.08 : 1)
                                .onTapGesture { withAnimation(Motion.change) { goalEmoji = e } }
                        }
                    }
                    .padding(.vertical, 4)
                }
                TextField("Name, e.g. New laptop", text: $goalName)
                AmountField(title: "Costs", text: $goalTargetText)
                Toggle("By a date", isOn: $hasDeadline.animation())
                if hasDeadline {
                    DatePicker("Reach by", selection: $deadline, in: Date.now..., displayedComponents: .date)
                }
            }
            if goalTarget > 0 {
                Section { GoalMath(target: goalTarget, deadline: hasDeadline ? deadline : nil, planned: planned) }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }

    private var tips: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                PageTitle("Weekly tips", "Once a week: how you did, what to tweak and how your goals are doing.")
                VStack(spacing: 12) {
                    TipRow(tip: Tip(id: "a", tone: .good, symbol: "target", title: "Your daily allowance: \(((income > 0 ? income - planned : 9_000) / 30).rounded(0).currency)",
                                    message: "Keep day-to-day spending under this for the rest of the month and you'll hit your saving plan."), compact: true)
                    Divider()
                    TipRow(tip: Tip(id: "b", tone: .warning, symbol: "fork.knife", title: "Food jumped",
                                    message: "More than usual this week. Back to normal next week and the difference goes to your goal."), compact: true)
                }
                .card()
                .reveal(1)

                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Weekly reminder", isOn: $tipsOn.animation())
                        .font(.headline)
                    if tipsOn {
                        Picker("Day", selection: $weekday) {
                            ForEach(1...7, id: \.self) { Text(Calendar.current.weekdaySymbols[$0 - 1]).tag($0) }
                        }
                        .pickerStyle(.menu)
                        Text("A notification at \(Profile.tipsHour):00 when your tips are ready. iPhone will ask for permission.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
                .card()
                .reveal(2)
            }
            .padding(24)
        }
    }

    private var done: some View {
        ScrollView {
            VStack(spacing: 24) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 72))
                    .foregroundStyle(.green)
                    .symbolEffect(.bounce, value: step)
                    .padding(.top, 32)
                    .reveal(0)
                VStack(spacing: 8) {
                    Text(name.trimmingCharacters(in: .whitespaces).isEmpty ? "You're all set!" : "You're all set, \(name.trimmingCharacters(in: .whitespaces))!")
                        .font(.largeTitle.bold())
                    Text("Here's your plan. Change any of it later in Settings.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)
                .reveal(1)

                VStack(spacing: 0) {
                    SummaryRow(symbol: "banknote", title: "Monthly income", value: income > 0 ? income.currency : "Not set")
                    Divider().padding(.leading, 44)
                    SummaryRow(symbol: "percent", title: "Saving plan",
                               value: income > 0 ? "\(Int(percent))% · \(planned.currency)" : "\(Int(percent))%")
                    Divider().padding(.leading, 44)
                    SummaryRow(symbol: "building.columns", title: "Account",
                               value: trimmedAccount.isEmpty ? (accounts.isEmpty ? "Add one later" : "\(accounts.count) already") : trimmedAccount)
                    Divider().padding(.leading, 44)
                    SummaryRow(symbol: "target", title: "Goal",
                               value: addsGoal ? "\(goalEmoji) \(trimmedGoal)" : (goals.isEmpty ? "Add one later" : "\(goals.count) already"))
                    Divider().padding(.leading, 44)
                    SummaryRow(symbol: "lightbulb", title: "Weekly tips",
                               value: tipsOn ? Calendar.current.weekdaySymbols[weekday - 1] : "Off")
                }
                .card()
                .reveal(2)
            }
            .padding(24)
        }
    }

    // MARK: Finish

    private func finish() {
        let store = UserDefaults.standard
        store.set(name.trimmingCharacters(in: .whitespaces), forKey: Profile.nameKey)
        store.set(income.double, forKey: Profile.incomeKey)
        store.set(payday, forKey: Profile.paydayKey)
        store.set(Int(percent), forKey: Profile.savingsPercentKey)
        store.set(Profile.encodeList(Categories.expense.map(\.name).filter(watched.contains)), forKey: Profile.watchedKey)
        store.set(tipsOn, forKey: Profile.tipsEnabledKey)
        store.set(weekday, forKey: Profile.tipsWeekdayKey)

        if !trimmedAccount.isEmpty {
            let account = Account(name: trimmedAccount, kind: accountKind, startingBalance: Money.parse(balanceText) ?? 0)
            if !accounts.contains(where: \.isDefaultForAutoLog) { account.isDefaultForAutoLog = true }
            context.insert(account)
        }
        if addsGoal {
            context.insert(SavingsGoal(name: trimmedGoal, emoji: goalEmoji, colorName: "blue",
                                       target: goalTarget, deadline: hasDeadline ? deadline : nil))
        }
        try? context.save()

        if tipsOn {
            Task {
                let allowed = await TipsReminder.enable(weekday: weekday)
                if !allowed { store.set(false, forKey: Profile.tipsEnabledKey) }
            }
        } else {
            TipsReminder.cancel()
        }
        withAnimation(Motion.entrance) { onboarded = true }
    }

    private func ordinal(_ n: Int) -> String {
        let f = NumberFormatter(); f.numberStyle = .ordinal
        return f.string(from: n as NSNumber) ?? "\(n)"
    }
}

// MARK: - Pieces

private struct PageTitle: View {
    let title: String
    let subtitle: String
    init(_ title: String, _ subtitle: String) { self.title = title; self.subtitle = subtitle }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.body).foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
        .reveal(0)
    }
}

private struct FeatureRow: View {
    let symbol: String
    let color: Color
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(color.gradient, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Theme.accent)
                .frame(width: 36, height: 36)
                .background(Theme.accent.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline)
                Text(text).font(.subheadline).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct SummaryRow: View {
    let symbol: String
    let title: String
    let value: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).foregroundStyle(Theme.accent).frame(width: 32)
            Text(title)
            Spacer()
            Text(value).foregroundStyle(.secondary).lineLimit(1).minimumScaleFactor(0.8)
        }
        .padding(.vertical, 10)
    }
}

/// "Save X a month / Y a week" for a goal, and whether it fits the saving plan.
struct GoalMath: View {
    let target: Decimal
    let deadline: Date?
    let planned: Decimal

    var body: some View {
        let cal = Calendar.current
        VStack(alignment: .leading, spacing: 8) {
            if let deadline {
                let months = max(cal.dateComponents([.month], from: .now, to: deadline).month ?? 0, 1)
                let monthly = (target / Decimal(months)).rounded(0)
                let weekly = (monthly * 12 / 52).rounded(0)
                Label {
                    Text("Save **\(monthly.currency)** a month, about **\(weekly.currency)** a week.")
                } icon: { Image(systemName: "calendar") }
                if planned > 0 {
                    if monthly <= planned {
                        Label("Fits in your saving plan (\(planned.currency) a month).", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                    } else {
                        let realistic = cal.date(byAdding: .month, value: Int((target / planned).double.rounded(.up)), to: .now) ?? deadline
                        Label("More than your plan of \(planned.currency) a month. With your plan you'd get there around \(realistic.formatted(.dateTime.month(.wide).year())).",
                              systemImage: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            } else if planned > 0 {
                let months = Int((target / planned).double.rounded(.up))
                let date = cal.date(byAdding: .month, value: months, to: .now) ?? .now
                Label("With your plan of \(planned.currency) a month, you'd have it around \(date.formatted(.dateTime.month(.wide).year())).",
                      systemImage: "calendar")
            } else {
                Label("Add your income to see how long it takes.", systemImage: "calendar")
                    .foregroundStyle(.secondary)
            }
        }
        .font(.subheadline)
        .animation(Motion.change, value: target)
    }
}

/// Currency menu shared by onboarding and Settings.
struct CurrencyPicker: View {
    @Binding var selection: String
    static let popular = ["MDL", "RON", "EUR", "USD", "GBP"]

    var body: some View {
        Picker("Currency", selection: $selection) {
            ForEach(Self.popular, id: \.self) { Text("\(Money.name(for: $0)) (\($0))").tag($0) }
            Divider()
            ForEach(Locale.commonISOCurrencyCodes.filter { !Self.popular.contains($0) }, id: \.self) {
                Text("\(Money.name(for: $0)) (\($0))").tag($0)
            }
        }
    }
}

/// Lays out chips in rows, wrapping to the next line when they don't fit.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, width: proposal.width ?? .infinity)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        return CGSize(width: proposal.width ?? rows.map(\.width).max() ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, width: bounds.width) {
            var x = bounds.minX
            for index in row.items {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row { var items: [Int] = []; var width: CGFloat = 0; var height: CGFloat = 0 }

    private func arrange(_ subviews: Subviews, width: CGFloat) -> [Row] {
        var rows = [Row()]
        for (i, view) in subviews.enumerated() {
            let size = view.sizeThatFits(.unspecified)
            if !rows[rows.count - 1].items.isEmpty, rows[rows.count - 1].width + spacing + size.width > width {
                rows.append(Row())
            }
            var row = rows[rows.count - 1]
            row.width += (row.items.isEmpty ? 0 : spacing) + size.width
            row.height = max(row.height, size.height)
            row.items.append(i)
            rows[rows.count - 1] = row
        }
        return rows
    }
}
