import SwiftUI

// MARK: - Topics

struct HelpTopic: Identifiable, Hashable {
    enum Demo { case tabs, addTransaction, swipe, goal, tracker, tips, plan }

    let id: String
    let title: String
    let symbol: String
    let color: Color
    let summary: String
    let steps: [String]
    var notes: [String] = []
    var demo: Demo?

    static func == (a: HelpTopic, b: HelpTopic) -> Bool { a.id == b.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}

enum HelpContent {
    static let all: [HelpTopic] = basics + money + app

    static let basics: [HelpTopic] = [
        HelpTopic(id: "tabs", title: "Getting around", symbol: "square.grid.3x1.below.line.grid.1x2", color: .blue,
                  summary: "The app has five tabs at the bottom. Each one has a single job.",
                  steps: ["**Overview**: your total balance, this month, charts and weekly tips.",
                          "**Activity**: every transaction, grouped by month.",
                          "**Goals**: what you're saving for and how far along you are.",
                          "**Trackers**: things you want to keep an eye on, like games or coffee.",
                          "**Accounts**: your cards and cash, with their balances."],
                  notes: ["Settings is the gear in the top-left corner of Overview.",
                          "This help is the ? button, on every tab."],
                  demo: .tabs),
        HelpTopic(id: "add", title: "Add spending or income", symbol: "plus.circle.fill", color: .green,
                  summary: "Log a purchase or money coming in, in a few seconds.",
                  steps: ["Tap **+** in the top-right corner of Overview or Activity.",
                          "Choose **Expense** or **Income** and type the amount.",
                          "Pick a **category**, the **date** and the **account** it came from.",
                          "Optionally add a note or put it in a **tracker**.",
                          "Tap **Save**. The account balance updates straight away."],
                  notes: ["Inside a tracker, its own + adds a purchase that's already in that tracker."],
                  demo: .addTransaction),
        HelpTopic(id: "edit", title: "Edit or delete", symbol: "hand.draw.fill", color: .orange,
                  summary: "Fix a mistake or remove something you logged twice.",
                  steps: ["In **Activity**, swipe a transaction **left** to delete it.",
                          "Swipe it **right** to edit it.",
                          "Or press and hold it for both options.",
                          "Goals, trackers and accounts: swipe left on them in their tab to delete."],
                  notes: ["Deleting an account keeps its transactions; they just aren't linked to an account any more."],
                  demo: .swipe),
        HelpTopic(id: "search", title: "Find a transaction", symbol: "magnifyingglass", color: .teal,
                  summary: "Look something up without scrolling through months.",
                  steps: ["Open **Activity** and pull the list down a little to show the search field.",
                          "Search by category, note or tracker name.",
                          "Use **All / Income / Expenses** at the top to filter."],
                  notes: ["Each month shows its total, so you can compare months at a glance."]),
    ]

    static let money: [HelpTopic] = [
        HelpTopic(id: "accounts", title: "Accounts and balances", symbol: "building.columns.fill", color: .indigo,
                  summary: "Keep each card and your cash separate, with balances that keep themselves up to date.",
                  steps: ["Open **Accounts** and tap **+**.",
                          "Give it a name, choose the type and type the balance it has **right now**.",
                          "From then on, every transaction you link to it moves the balance."],
                  notes: ["Tap an account to change its name or starting balance.",
                          "The total on Overview adds up all your accounts."]),
        HelpTopic(id: "goals", title: "Saving for a goal", symbol: "target", color: .red,
                  summary: "Name what you're saving for, set the price, and watch it fill up.",
                  steps: ["Open **Goals** and tap **+**.",
                          "Name it, pick an emoji and set the **target** amount.",
                          "Turn on **Deadline** to see how much to save each month.",
                          "Open the goal and tap **Add Money** whenever you put something aside.",
                          "Took some out? Use **Withdraw**."],
                  notes: ["Weekly tips tell you if your goals fit what you usually have left, and suggest a realistic date if not."],
                  demo: .goal),
        HelpTopic(id: "trackers", title: "Trackers and budgets", symbol: "square.grid.2x2.fill", color: .purple,
                  summary: "Follow one kind of spending, like games or coffee, with an optional monthly budget.",
                  steps: ["Open **Trackers** and tap **+**.",
                          "Choose a name, an emoji, a color and a **default category**.",
                          "Optionally set a **monthly budget**.",
                          "Add purchases from inside the tracker, or pick the tracker when you log a transaction."],
                  notes: ["The bar turns red when you go over the budget.",
                          "Weekly tips warn you when a tracker is close to or over its budget."],
                  demo: .tracker),
        HelpTopic(id: "plan", title: "Your saving plan", symbol: "percent", color: .mint,
                  summary: "Tell the app roughly what you earn and how much you'd like to keep.",
                  steps: ["Open **Settings** (the gear on Overview).",
                          "Under **Your plan**, set your monthly income and payday.",
                          "Choose how much to save each month, in percent.",
                          "Pick categories to **keep an eye on**."],
                  notes: ["Your daily allowance in weekly tips comes from this plan.",
                          "It stays on your phone and is included in backups."],
                  demo: .plan),
        HelpTopic(id: "tips", title: "Weekly tips", symbol: "lightbulb.fill", color: .yellow,
                  summary: "Once a week, see how you did and what to tweak.",
                  steps: ["The top two tips are on **Overview**; tap **See all** for the rest.",
                          "Tips compare the last 7 days with a usual week, and check your plan, goals and trackers.",
                          "Turn on the **weekly reminder** in Settings and pick a day."],
                  notes: ["Rent, bills and subscriptions are left out of week-to-week comparisons, since they come once a month.",
                          "The more weeks you log, the better the comparisons get."],
                  demo: .tips),
    ]

    static let app: [HelpTopic] = [
        HelpTopic(id: "backup", title: "Backup and export", symbol: "externaldrive.fill", color: .gray,
                  summary: "Keep a copy of everything, or open your data in a spreadsheet.",
                  steps: ["Open **Settings** and scroll to **Export**.",
                          "**Save Backup** makes a file you can keep in Files or iCloud Drive.",
                          "**Export Transactions (CSV)** opens in Numbers, Excel or Google Sheets.",
                          "**Restore from Backup…** brings a backup back."],
                  notes: ["Restoring replaces everything currently in the app, so save a fresh backup first."]),
        HelpTopic(id: "look", title: "Theme, color and icon", symbol: "paintpalette.fill", color: .pink,
                  summary: "Make the app look the way you like.",
                  steps: ["Open **Settings**.",
                          "Pick **Automatic**, **Light** or **Dark** under Appearance.",
                          "Choose an **accent color** for buttons and highlights.",
                          "Pick an **app icon** for your Home Screen."],
                  notes: ["Changing the currency only changes how amounts are shown; numbers aren't converted."]),
    ]

    static func topics(_ ids: [String]) -> [HelpTopic] { ids.compactMap { id in all.first { $0.id == id } } }
}

// MARK: - Button and screens

/// The ? button shown in the corner of every tab. `related` puts that screen's topics first.
struct HelpButton: View {
    var related: [String] = []
    @State private var showing = false

    var body: some View {
        Button { showing = true } label: { Image(systemName: "questionmark.circle") }
            .accessibilityLabel("Help")
            .sheet(isPresented: $showing) { HelpView(related: related) }
    }
}

struct HelpView: View {
    var related: [String] = []
    @Environment(\.dismiss) private var dismiss
    @State private var search = ""

    private func matches(_ topic: HelpTopic) -> Bool {
        guard !search.isEmpty else { return true }
        let text = ([topic.title, topic.summary] + topic.steps + topic.notes).joined(separator: " ")
        return text.localizedCaseInsensitiveContains(search)
    }

    var body: some View {
        NavigationStack {
            List {
                if search.isEmpty && !related.isEmpty {
                    section("On this screen", HelpContent.topics(related))
                }
                section("Basics", HelpContent.basics.filter(matches))
                section("Your money", HelpContent.money.filter(matches))
                section("The app", HelpContent.app.filter(matches))
            }
            .searchable(text: $search, prompt: "Search help")
            .overlay {
                if !search.isEmpty && !HelpContent.all.contains(where: matches) {
                    ContentUnavailableView.search(text: search)
                }
            }
            .navigationTitle("Help")
            .navigationDestination(for: HelpTopic.self) { HelpTopicView(topic: $0) }
            .toolbar { Button("Done") { dismiss() } }
        }
    }

    @ViewBuilder
    private func section(_ title: String, _ topics: [HelpTopic]) -> some View {
        if !topics.isEmpty {
            Section(title) {
                ForEach(topics) { topic in
                    NavigationLink(value: topic) {
                        HStack(spacing: 12) {
                            Image(systemName: topic.symbol)
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(.white)
                                .frame(width: 30, height: 30)
                                .background(topic.color.gradient, in: RoundedRectangle(cornerRadius: 7, style: .continuous))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(topic.title)
                                Text(topic.summary).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                            }
                            if topic.demo != nil {
                                Spacer()
                                Image(systemName: "play.circle").foregroundStyle(.secondary).font(.caption)
                                    .accessibilityLabel("Has an animation")
                            }
                        }
                    }
                }
            }
        }
    }
}

struct HelpTopicView: View {
    let topic: HelpTopic

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let demo = topic.demo {
                    DemoScreen { demoView(demo) }.reveal(0)
                }
                Text(topic.summary).font(.title3).foregroundStyle(.secondary).reveal(1)

                VStack(alignment: .leading, spacing: 14) {
                    ForEach(Array(topic.steps.enumerated()), id: \.offset) { i, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(i + 1)")
                                .font(.subheadline.weight(.bold).monospacedDigit())
                                .foregroundStyle(topic.color)
                                .frame(width: 26, height: 26)
                                .background(topic.color.opacity(0.15), in: Circle())
                            Text(LocalizedStringKey(step)).fixedSize(horizontal: false, vertical: true)
                            Spacer(minLength: 0)
                        }
                    }
                }
                .card()
                .reveal(2)

                if !topic.notes.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Good to know", systemImage: "info.circle").font(.headline)
                        ForEach(topic.notes, id: \.self) { note in
                            Text(LocalizedStringKey(note)).font(.subheadline).foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .card()
                    .reveal(3)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(topic.title)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private func demoView(_ demo: HelpTopic.Demo) -> some View {
        switch demo {
        case .tabs: TabsDemo()
        case .addTransaction: AddTransactionDemo()
        case .swipe: SwipeDemo()
        case .goal: GoalDemo()
        case .tracker: TrackerDemo()
        case .tips: TipsDemo()
        case .plan: PlanDemo()
        }
    }
}

// MARK: - Animated demos
//
// Small looping animations drawn in SwiftUI, like a GIF of the real screen.
// With Reduce Motion on they show a still frame instead.

private struct DemoScreen<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: 250)
            .background(Color(.systemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous).strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
            .padding(10)
            .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 30, style: .continuous))
            .accessibilityHidden(true)
    }
}

/// The circle that shows where a finger taps.
private struct Touch: View {
    var pressed: Bool
    var body: some View {
        Circle()
            .fill(Color.primary.opacity(0.25))
            .overlay(Circle().strokeBorder(Color.primary.opacity(0.5), lineWidth: 2))
            .frame(width: 34, height: 34)
            .scaleEffect(pressed ? 0.8 : 1)
    }
}

/// Runs `phases` in a loop; with Reduce Motion it just shows `still`.
private struct Looping<Phase: Equatable, Content: View>: View {
    let phases: [Phase]
    let still: Phase
    let timing: (Phase) -> Animation
    @ViewBuilder let content: (Phase) -> Content
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        if reduceMotion {
            content(still)
        } else {
            PhaseAnimator(phases) { phase in content(phase) } animation: { timing($0) }
        }
    }
}

private struct DemoRow: View {
    let symbol: String
    let title: String
    let amount: Decimal
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: symbol).font(.caption).foregroundStyle(Theme.accent)
                .frame(width: 26, height: 26).background(Theme.accent.opacity(0.15), in: Circle())
            Text(title).font(.subheadline)
            Spacer()
            Text("−" + amount.currency).font(.subheadline.monospacedDigit())
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct TabsDemo: View {
    private let tabs: [(String, String)] = [("Overview", "chart.pie"), ("Activity", "list.bullet"), ("Goals", "target"),
                                            ("Trackers", "square.grid.2x2"), ("Accounts", "building.columns")]
    var body: some View {
        Looping(phases: Array(0..<5), still: 0, timing: { _ in .snappy(duration: 0.35).delay(0.9) }) { i in
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(tabs[i].0).font(.title2.bold()).contentTransition(.opacity)
                    ForEach(0..<3, id: \.self) { row in
                        RoundedRectangle(cornerRadius: 8).fill(Color(.secondarySystemGroupedBackground))
                            .frame(height: 30)
                            .overlay(alignment: .leading) {
                                Image(systemName: tabs[i].1).font(.caption).foregroundStyle(Theme.accent).padding(.leading, 10)
                            }
                            .opacity(1 - Double(row) * 0.25)
                    }
                }
                .padding(16)
                Spacer(minLength: 0)
                HStack {
                    ForEach(Array(tabs.enumerated()), id: \.offset) { j, tab in
                        VStack(spacing: 2) {
                            Image(systemName: tab.1).font(.system(size: 15))
                            Text(tab.0).font(.system(size: 8))
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(i == j ? Theme.accent : .secondary)
                        .scaleEffect(i == j ? 1.1 : 1)
                    }
                }
                .padding(.vertical, 8)
                .background(.bar, in: Capsule())
                .padding(.horizontal, 10).padding(.bottom, 10)
            }
        }
    }
}

private struct AddTransactionDemo: View {
    enum Step: CaseIterable { case list, tapPlus, sheet, typed, tapSave, saved }

    var body: some View {
        Looping(phases: Step.allCases, still: .saved, timing: { step in
            switch step {
            case .list: .easeInOut(duration: 0.3).delay(1.2)
            case .tapPlus, .tapSave: .easeOut(duration: 0.2).delay(0.4)
            default: .spring(duration: 0.45, bounce: 0.15).delay(0.7)
            }
        }) { step in
            ZStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Activity").font(.title2.bold())
                        Spacer()
                        Image(systemName: "plus").font(.headline).foregroundStyle(Theme.accent)
                            .frame(width: 32, height: 32).background(Color(.secondarySystemGroupedBackground), in: Circle())
                            .overlay { if step == .tapPlus { Touch(pressed: true) } }
                    }
                    if step == .saved {
                        DemoRow(symbol: "cup.and.saucer.fill", title: "Coffee", amount: 45)
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }
                    DemoRow(symbol: "cart.fill", title: "Linella", amount: 120)
                    DemoRow(symbol: "fork.knife", title: "Glovo", amount: 85)
                    DemoRow(symbol: "car.fill", title: "Taxi", amount: 60)
                }
                .padding(16)

                if [.sheet, .typed, .tapSave].contains(step) {
                    VStack(spacing: 10) {
                        Capsule().fill(Color.secondary.opacity(0.4)).frame(width: 36, height: 4)
                        HStack {
                            Text("New Transaction").font(.headline)
                            Spacer()
                            Text("Save").font(.headline).foregroundStyle(Theme.accent)
                                .overlay { if step == .tapSave { Touch(pressed: true) } }
                        }
                        HStack {
                            Text("Amount")
                            Spacer()
                            Text(step == .sheet ? "0" : "45").font(.title3.bold().monospacedDigit())
                                .contentTransition(.numericText())
                                .foregroundStyle(step == .sheet ? .secondary : .primary)
                        }
                        .padding(10).background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                        HStack {
                            Label("Food", systemImage: "fork.knife")
                            Spacer()
                            Text("Coffee").foregroundStyle(.secondary)
                        }
                        .font(.subheadline)
                        .padding(10).background(Color(.tertiarySystemFill), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground), in: UnevenRoundedRectangle(topLeadingRadius: 18, topTrailingRadius: 18))
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom))
                }
            }
        }
    }
}

private struct SwipeDemo: View {
    var body: some View {
        // Row offset: 0 rest, negative shows Delete, positive shows Edit.
        Looping(phases: [0.0, -96, 0, 84, 0], still: -96, timing: { _ in .spring(duration: 0.5, bounce: 0.1).delay(0.8) }) { offset in
            VStack(alignment: .leading, spacing: 10) {
                Text("Activity").font(.title2.bold())
                DemoRow(symbol: "cart.fill", title: "Linella", amount: 120).opacity(0.5)
                ZStack {
                    HStack(spacing: 0) {
                        Label("Edit", systemImage: "pencil").labelStyle(.iconOnly)
                            .frame(width: 84).frame(maxHeight: .infinity).background(.blue)
                        Spacer()
                        Label("Delete", systemImage: "trash").labelStyle(.iconOnly)
                            .frame(width: 96).frame(maxHeight: .infinity).background(.red)
                    }
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    DemoRow(symbol: "fork.knife", title: "Glovo", amount: 85)
                        .offset(x: offset)
                        .overlay(alignment: offset < 0 ? .trailing : .leading) {
                            if offset != 0 { Touch(pressed: true).offset(x: offset < 0 ? offset - 20 : offset + 20) }
                        }
                }
                .frame(height: 42)
                DemoRow(symbol: "car.fill", title: "Taxi", amount: 60).opacity(0.5)
                Text(offset < 0 ? "Swipe left: Delete" : offset > 0 ? "Swipe right: Edit" : " ")
                    .font(.footnote.weight(.medium)).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .contentTransition(.opacity)
            }
            .padding(16)
        }
    }
}

private struct GoalDemo: View {
    private let target: Decimal = 10_000
    var body: some View {
        Looping(phases: [Decimal(3_000), 3_500, 5_000, 7_500], still: 5_000, timing: { _ in .spring(duration: 0.7, bounce: 0.2).delay(0.9) }) { saved in
            VStack(spacing: 14) {
                Text("💻").font(.system(size: 44))
                Text(saved.currency).font(.title.bold().monospacedDigit())
                    .contentTransition(.numericText(value: saved.double))
                Text("saved of \(target.currency)").font(.subheadline).foregroundStyle(.secondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemFill))
                        Capsule().fill(Theme.accent).frame(width: geo.size.width * (saved / target).double)
                    }
                }
                .frame(height: 10)
                HStack(spacing: 10) {
                    Label("Add Money", systemImage: "plus").font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Theme.accent.opacity(0.18), in: Capsule())
                        .foregroundStyle(Theme.accent)
                        .overlay { if saved != 3_000 { Touch(pressed: true) } }
                }
            }
            .padding(20)
        }
    }
}

private struct TrackerDemo: View {
    private let budget: Decimal = 600
    var body: some View {
        Looping(phases: [Decimal(150), 380, 520, 690], still: 520, timing: { _ in .spring(duration: 0.6).delay(0.9) }) { spent in
            let over = spent > budget
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("🎮").font(.title).frame(width: 52, height: 52).background(Color.purple.opacity(0.2), in: Circle())
                    VStack(alignment: .leading) {
                        Text("Video Games").font(.headline)
                        Text("Budget \(budget.currency) a month").font(.caption).foregroundStyle(.secondary)
                    }
                }
                Text(spent.currency).font(.title.bold().monospacedDigit())
                    .contentTransition(.numericText(value: spent.double))
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemFill))
                        Capsule().fill(over ? Color.red : spent >= budget * 0.8 ? .orange : .purple)
                            .frame(width: geo.size.width * min((spent / budget).double, 1))
                    }
                }
                .frame(height: 10)
                Text(over ? "\((spent - budget).currency) over your budget" : "\((budget - spent).currency) left this month")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(over ? .red : .secondary)
                    .contentTransition(.opacity)
            }
            .padding(20)
        }
    }
}

private struct TipsDemo: View {
    private let tips: [Tip] = [
        Tip(id: "1", tone: .good, symbol: "target", title: "Daily allowance", message: "Stay under this each day to hit your plan."),
        Tip(id: "2", tone: .warning, symbol: "fork.knife", title: "Food jumped", message: "More than usual this week."),
        Tip(id: "3", tone: .good, symbol: "checkmark.seal", title: "💻 Laptop on track", message: "Keep saving the same each week."),
    ]
    var body: some View {
        Looping(phases: Array(0...3), still: 3, timing: { n in .spring(duration: 0.45, bounce: 0.2).delay(n == 3 ? 1.6 : 0.6) }) { shown in
            VStack(alignment: .leading, spacing: 8) {
                Label("Weekly tips", systemImage: "lightbulb.fill").font(.headline)
                ForEach(Array(tips.prefix(shown).enumerated()), id: \.element.id) { _, tip in
                    TipRow(tip: tip, compact: true)
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
                Spacer(minLength: 0)
            }
            .padding(16)
        }
    }
}

private struct PlanDemo: View {
    private let income: Decimal = 15_000
    var body: some View {
        Looping(phases: [10, 20, 30, 20], still: 20, timing: { _ in .spring(duration: 0.6).delay(0.9) }) { percent in
            VStack(alignment: .leading, spacing: 14) {
                Text("Save each month").font(.headline)
                HStack(alignment: .firstTextBaseline) {
                    Text("\(percent)%").font(.system(size: 44, weight: .bold, design: .rounded))
                        .contentTransition(.numericText(value: Double(percent)))
                    Spacer()
                    Text((income * Decimal(percent) / 100).currency).font(.headline.monospacedDigit())
                        .contentTransition(.numericText(value: Double(percent)))
                }
                GeometryReader { geo in
                    let x = geo.size.width * CGFloat(percent - 5) / 45
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(.tertiarySystemFill)).frame(height: 6)
                        Capsule().fill(Theme.accent).frame(width: x, height: 6)
                        Circle().fill(.white).shadow(radius: 2).frame(width: 26, height: 26)
                            .overlay(Touch(pressed: true).opacity(0.8))
                            .offset(x: x - 13)
                    }
                    .frame(maxHeight: .infinity)
                }
                .frame(height: 30)
                Text("of \(income.currency) income").font(.caption).foregroundStyle(.secondary)
            }
            .padding(20)
        }
    }
}
