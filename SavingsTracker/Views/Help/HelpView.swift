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
            // Top-aligned: if a demo grows taller than the screen it overflows at the bottom,
            // instead of being re-centred and jumping up.
            .frame(height: 250, alignment: .top)
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
    /// Starts looping only after the page has finished sliding in, so the two motions don't mix.
    @State private var started = false

    var body: some View {
        if reduceMotion {
            content(still)
        } else if started {
            PhaseAnimator(phases) { phase in content(phase) } animation: { timing($0) }
        } else {
            content(phases[0])
                .task {
                    try? await Task.sleep(for: .milliseconds(700))
                    started = true
                }
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
    private struct Row { let icon: String; let title: String; let value: String; var color: Color = .primary }
    private struct Page { let name: String; let symbol: String; let rows: [Row] }

    private var pages: [Page] {
        func money(_ v: Decimal) -> String { v.formatted(.currency(code: Money.code).precision(.fractionLength(0))) }
        return [
            Page(name: "Overview", symbol: "chart.pie", rows: [
                Row(icon: "💰", title: "Total balance", value: money(87_773)),
                Row(icon: "📈", title: "Saved this month", value: money(8_588), color: .green),
                Row(icon: "💡", title: "Weekly tips", value: "2 new")]),
            Page(name: "Activity", symbol: "list.bullet", rows: [
                Row(icon: "🛒", title: "Linella", value: "−" + money(120)),
                Row(icon: "🍔", title: "Glovo", value: "−" + money(85)),
                Row(icon: "💼", title: "Salary", value: "+" + money(18_500), color: .green)]),
            Page(name: "Goals", symbol: "target", rows: [
                Row(icon: "💻", title: "New Laptop", value: "60%"),
                Row(icon: "🏖️", title: "Summer Trip", value: "30%"),
                Row(icon: "🛟", title: "Emergency Fund", value: "75%")]),
            Page(name: "Trackers", symbol: "square.grid.2x2", rows: [
                Row(icon: "🎮", title: "Video Games", value: "\(money(480)) / \(money(600))"),
                Row(icon: "☕️", title: "Coffee", value: "\(money(115)) / \(money(300))"),
                Row(icon: "🎬", title: "Cinema", value: "\(money(90)) / \(money(200))")]),
            Page(name: "Accounts", symbol: "building.columns", rows: [
                Row(icon: "💳", title: "MAIB", value: money(62_828)),
                Row(icon: "🏦", title: "Moldindconbank", value: money(23_500)),
                Row(icon: "💵", title: "Cash", value: money(1_445))]),
        ]
    }

    var body: some View {
        // Goes 0 → 4 and back, so every move is one tab to the next, like tapping through them.
        Looping(phases: [0, 1, 2, 3, 4, 3, 2, 1], still: 0,
                // Ease in and out with no spring, so the slide never rolls back past the page.
                timing: { _ in .timingCurve(0.65, 0, 0.35, 1, duration: 0.6).delay(1.1) }) { i in
            GeometryReader { geo in
                let width = geo.size.width
                let tabWidth = (width - 20) / CGFloat(pages.count)
                VStack(spacing: 0) {
                    // The screens sit side by side and slide, so nothing pops in.
                    HStack(spacing: 0) {
                        ForEach(pages, id: \.name) { page in
                            pageView(page).frame(width: width)
                        }
                    }
                    .frame(width: width, alignment: .leading)
                    .offset(x: -CGFloat(i) * width)
                    .frame(maxHeight: .infinity, alignment: .top)
                    .clipped()

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Theme.accent.opacity(0.18))
                            .frame(width: tabWidth - 6, height: 40)
                            .offset(x: CGFloat(i) * tabWidth + 3)
                        HStack(spacing: 0) {
                            ForEach(Array(pages.enumerated()), id: \.offset) { j, page in
                                VStack(spacing: 2) {
                                    Image(systemName: page.symbol).font(.system(size: 15))
                                    Text(page.name).font(.system(size: 8))
                                }
                                .frame(width: tabWidth)
                                .foregroundStyle(i == j ? Theme.accent : .secondary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .background(.bar, in: Capsule())
                    .padding(.horizontal, 10).padding(.bottom, 10)
                }
            }
        }
    }

    private func pageView(_ page: Page) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(page.name).font(.title2.bold())
            ForEach(page.rows, id: \.title) { row in
                HStack(spacing: 8) {
                    Text(row.icon).font(.footnote)
                    Text(row.title).font(.footnote).lineLimit(1)
                    Spacer(minLength: 6)
                    Text(row.value).font(.footnote.weight(.semibold).monospacedDigit())
                        .foregroundStyle(row.color).lineLimit(1).minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 10)
                .frame(height: 32)
                .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct AddTransactionDemo: View {
    /// One step at a time: tap +, the form slides up, 45 pops in, tap Save,
    /// the form slides away, and only then the new row appears.
    enum Step: CaseIterable { case list, tapPlus, sheet, typed, tapSave, closed, saved }

    private func sheetShown(_ step: Step) -> Bool { [.sheet, .typed, .tapSave].contains(step) }

    var body: some View {
        Looping(phases: Step.allCases, still: .saved, timing: { step in
            switch step {
            case .list: .easeInOut(duration: 0.3).delay(1.4)
            case .tapPlus, .tapSave: .easeOut(duration: 0.15).delay(0.45)
            case .sheet, .closed: .timingCurve(0.3, 0, 0.2, 1, duration: 0.45).delay(0.25)
            case .typed: .spring(duration: 0.4, bounce: 0.35).delay(0.5)
            case .saved: .spring(duration: 0.45, bounce: 0.15).delay(0.15)
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

                if sheetShown(step) {
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
                            // 0 fades out and 45 pops in on the same spot (both pinned to the right),
                            // so the number never slides sideways.
                            ZStack(alignment: .trailing) {
                                if step == .sheet {
                                    Text("0").foregroundStyle(.secondary)
                                        .transition(.opacity)
                                } else {
                                    Text("45")
                                        .transition(.asymmetric(
                                            insertion: .scale(scale: 0.5, anchor: .trailing).combined(with: .opacity),
                                            removal: .opacity))
                                }
                            }
                            .font(.title3.bold().monospacedDigit())
                            .frame(width: 60, alignment: .trailing)
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
                    .shadow(color: .black.opacity(0.12), radius: 10, y: -2)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom))
                    // Stays above the list while it slides away, instead of dropping behind it.
                    .zIndex(1)
                }
            }
            // Always fill the screen from the top, so the list doesn't jump when the form opens or a row is added.
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        Looping(phases: [Decimal(3_000), 3_500, 5_000, 7_500], still: 5_000, timing: { _ in .timingCurve(0.65, 0, 0.35, 1, duration: 0.7).delay(0.9) }) { saved in
            VStack(spacing: 14) {
                Text("💻").font(.system(size: 44))
                CountingText.money(saved, cents: false).font(.title.bold().monospacedDigit())
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
        Looping(phases: [Decimal(150), 380, 520, 690], still: 520, timing: { _ in .timingCurve(0.65, 0, 0.35, 1, duration: 0.7).delay(0.9) }) { spent in
            let over = spent > budget
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 12) {
                    Text("🎮").font(.title).frame(width: 52, height: 52).background(Color.purple.opacity(0.2), in: Circle())
                    VStack(alignment: .leading) {
                        Text("Video Games").font(.headline)
                        Text("Budget \(budget.currency) a month").font(.caption).foregroundStyle(.secondary)
                    }
                }
                CountingText.money(spent, cents: false).font(.title.bold().monospacedDigit())
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
    @State private var shown = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // Plays once: the tips arrive one by one, then stay on screen.
        VStack(alignment: .leading, spacing: 8) {
            Label("Weekly tips", systemImage: "lightbulb.fill").font(.headline)
            ForEach(tips.prefix(shown)) { tip in
                TipRow(tip: tip, compact: true)
                    .padding(10)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .task {
            guard shown == 0 else { return }
            if reduceMotion { shown = tips.count; return }
            try? await Task.sleep(for: .milliseconds(700))
            for n in 1...tips.count {
                withAnimation(.spring(duration: 0.45, bounce: 0.2)) { shown = n }
                try? await Task.sleep(for: .milliseconds(550))
            }
        }
    }
}

private struct PlanDemo: View {
    var body: some View {
        Looping(phases: [10.0, 20, 30, 20], still: 20, timing: { _ in .timingCurve(0.65, 0, 0.35, 1, duration: 0.7).delay(1.0) }) { percent in
            PlanFigure(percent: percent)
        }
    }
}

/// Percent, amount and slider all come from one animated value, so they always move together.
private struct PlanFigure: View, Animatable {
    var percent: Double
    private let income: Decimal = 15_000

    var animatableData: Double {
        get { percent }
        set { percent = newValue }
    }

    var body: some View {
        let amount = (income.double * percent / 100).rounded()
        VStack(alignment: .leading, spacing: 14) {
            Text("Save each month").font(.headline)
            HStack(alignment: .firstTextBaseline) {
                Text("\(Int(percent.rounded()))%").font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                Spacer()
                Text(amount.formatted(.currency(code: Money.code).precision(.fractionLength(0))))
                    .font(.headline.monospacedDigit())
            }
            .contentTransition(.identity)
            // The whole bar is your income; the filled part is the share you save,
            // so 20% fills exactly a fifth of it.
            GeometryReader { geo in
                let x = geo.size.width * CGFloat(percent) / 100
                ZStack(alignment: .leading) {
                    Capsule().fill(Color(.tertiarySystemFill)).frame(height: 8)
                    Capsule().fill(Theme.accent).frame(width: x, height: 8)
                    Circle().fill(.white).shadow(radius: 2).frame(width: 26, height: 26)
                        .overlay(Touch(pressed: true).opacity(0.8))
                        .offset(x: x - 13)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(height: 30)
            HStack {
                Text("Saved").foregroundStyle(Theme.accent)
                Spacer()
                Text("Your income: \(income.formatted(.currency(code: Money.code).precision(.fractionLength(0))))")
                    .foregroundStyle(.secondary)
            }
            .font(.caption)
        }
        .padding(20)
        // This view already receives every in-between value; animating the bar again on top
        // would make it trail behind the numbers.
        .transaction { $0.animation = nil }
    }
}
