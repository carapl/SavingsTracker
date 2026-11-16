import SwiftUI
import SwiftData

struct GoalsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SavingsGoal.createdAt, animation: Motion.change) private var goals: [SavingsGoal]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            List {
                if !goals.isEmpty {
                    Section {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Saved toward goals").font(.subheadline).foregroundStyle(.secondary)
                                Text(goals.sum(\.saved).currency).font(.title2.bold()).monospacedDigit()
                                    .rollingNumber(goals.sum(\.saved))
                            }
                            Spacer()
                            Text("of \(goals.sum(\.target).currency)").foregroundStyle(.secondary)
                        }
                    }
                }
                ForEach(goals) { goal in
                    NavigationLink { GoalDetailView(goal: goal) } label: { GoalRow(goal: goal) }
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(goals[i]) }
                }
            }
            .overlay {
                if goals.isEmpty {
                    ContentUnavailableView("No goals yet", systemImage: "target",
                                           description: Text("Create a goal like \"Holiday\" or \"New laptop\" and watch it fill up."))
                }
            }
            .navigationTitle("Goals")
            .toolbar {
                Button { showingNew = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add goal")
            }
            .sheet(isPresented: $showingNew) { GoalForm() }
        }
    }
}

struct GoalRow: View {
    let goal: SavingsGoal

    var body: some View {
        HStack(spacing: 12) {
            EmojiBadge(emoji: goal.emoji, color: Palette.color(goal.colorName))
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(goal.name).font(.headline)
                    Spacer()
                    if goal.isComplete {
                        Label("Done", systemImage: "checkmark.seal.fill").labelStyle(.iconOnly).foregroundStyle(.green)
                    } else {
                        Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                            .font(.subheadline).foregroundStyle(.secondary)
                    }
                }
                ProgressView(value: goal.progress).tint(Palette.color(goal.colorName))
                Text("\(goal.saved.currency) of \(goal.target.currency)")
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
        }
        .padding(.vertical, 4)
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 14

    var body: some View {
        ZStack {
            Circle().stroke(color.opacity(0.2), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeOut, value: progress)
        }
    }
}

struct GoalDetailView: View {
    @Environment(\.modelContext) private var context
    let goal: SavingsGoal

    @State private var depositMode: DepositForm.Mode?
    @State private var editing = false

    var body: some View {
        let color = Palette.color(goal.colorName)
        List {
            Section {
                VStack(spacing: 16) {
                    ZStack {
                        ProgressRing(progress: goal.progress, color: color)
                        VStack(spacing: 2) {
                            Text(goal.emoji).font(.largeTitle)
                            Text(goal.progress, format: .percent.precision(.fractionLength(0)))
                                .font(.title2.bold())
                        }
                    }
                    .frame(width: 170, height: 170)
                    .padding(.top)

                    VStack(spacing: 4) {
                        Text(goal.saved.currency).font(.title.bold()).monospacedDigit()
                            .rollingNumber(goal.saved)
                        Text("saved of \(goal.target.currency)").foregroundStyle(.secondary)
                    }

                    if goal.isComplete {
                        Label("Goal reached!", systemImage: "party.popper").foregroundStyle(.green).font(.headline)
                    } else if let deadline = goal.deadline {
                        VStack(spacing: 2) {
                            Text("\(goal.remaining.currency) to go by \(deadline.formatted(date: .abbreviated, time: .omitted))")
                            if let monthly = goal.monthlyNeeded {
                                Text("About \(monthly.currency) a month").foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    } else {
                        Text("\(goal.remaining.currency) to go").font(.subheadline)
                    }

                    HStack(spacing: 12) {
                        Button { depositMode = .add } label: {
                            Label("Add Money", systemImage: "plus").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        Button { depositMode = .withdraw } label: {
                            Label("Withdraw", systemImage: "minus").frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .tint(color)
                    .controlSize(.large)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 8)
            }

            Section("History") {
                if goal.sortedDeposits.isEmpty {
                    Text("No deposits yet").foregroundStyle(.secondary)
                }
                ForEach(goal.sortedDeposits) { deposit in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(deposit.note.isEmpty ? (deposit.amount >= 0 ? "Deposit" : "Withdrawal") : deposit.note)
                            Text(deposit.date, format: .dateTime.day().month().year())
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text((deposit.amount >= 0 ? "+" : "") + deposit.amount.currency)
                            .monospacedDigit()
                            .foregroundStyle(deposit.amount >= 0 ? .green : .red)
                    }
                }
                .onDelete { offsets in
                    let items = goal.sortedDeposits
                    for i in offsets { context.delete(items[i]) }
                }
            }
        }
        .navigationTitle(goal.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Edit") { editing = true } }
        .sheet(isPresented: $editing) { GoalForm(goal: goal) }
        .sheet(item: $depositMode) { DepositForm(goal: goal, mode: $0) }
    }
}

struct DepositForm: View {
    enum Mode: Identifiable { case add, withdraw; var id: Self { self } }

    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let goal: SavingsGoal
    let mode: Mode

    @State private var amountText = ""
    @State private var note = ""
    @State private var date = Date.now

    private var amount: Decimal? {
        guard let value = Money.parse(amountText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                AmountField(title: "Amount", text: $amountText)
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Note (optional)", text: $note)
            }
            .navigationTitle(mode == .add ? "Add to \(goal.name)" : "Withdraw from \(goal.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let amount else { return }
                        let deposit = GoalDeposit(amount: mode == .add ? amount : -amount, note: note, date: date)
                        context.insert(deposit)
                        deposit.goal = goal
                        dismiss()
                    }
                    .disabled(amount == nil)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

struct GoalForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let goal: SavingsGoal?

    @State private var name: String
    @State private var emoji: String
    @State private var colorName: String
    @State private var targetText: String
    @State private var hasDeadline: Bool
    @State private var deadline: Date

    init(goal: SavingsGoal? = nil) {
        self.goal = goal
        _name = State(initialValue: goal?.name ?? "")
        _emoji = State(initialValue: goal?.emoji ?? "🎯")
        _colorName = State(initialValue: goal?.colorName ?? "blue")
        _targetText = State(initialValue: goal.map { Money.editText($0.target) } ?? "")
        _hasDeadline = State(initialValue: goal?.deadline != nil)
        _deadline = State(initialValue: goal?.deadline
                          ?? Calendar.current.date(byAdding: .month, value: 6, to: .now) ?? .now)
    }

    private var target: Decimal? {
        guard let value = Money.parse(targetText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, e.g. Holiday", text: $name)
                    EmojiField(emoji: $emoji)
                    ColorChooser(selection: $colorName)
                }
                Section {
                    AmountField(title: "Target", text: $targetText)
                    Toggle("Deadline", isOn: $hasDeadline.animation())
                    if hasDeadline {
                        DatePicker("Reach by", selection: $deadline, in: Date.now..., displayedComponents: .date)
                    }
                }
            }
            .navigationTitle(goal == nil ? "New Goal" : "Edit Goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(target == nil || name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        guard let target else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let finalEmoji = emoji.isEmpty ? "🎯" : emoji
        if let goal {
            goal.name = trimmed
            goal.emoji = finalEmoji
            goal.colorName = colorName
            goal.target = target
            goal.deadline = hasDeadline ? deadline : nil
        } else {
            context.insert(SavingsGoal(name: trimmed, emoji: finalEmoji, colorName: colorName,
                                       target: target, deadline: hasDeadline ? deadline : nil))
        }
        dismiss()
    }
}
