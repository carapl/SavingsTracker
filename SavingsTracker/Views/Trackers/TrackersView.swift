import SwiftUI
import SwiftData
import Charts

struct TrackersView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Tracker.createdAt) private var trackers: [Tracker]
    @State private var showingNew = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(trackers) { tracker in
                    NavigationLink { TrackerDetailView(tracker: tracker) } label: { TrackerRow(tracker: tracker) }
                }
                .onDelete { offsets in
                    for i in offsets { context.delete(trackers[i]) }
                }
            }
            .overlay {
                if trackers.isEmpty {
                    ContentUnavailableView {
                        Label("No trackers yet", systemImage: "square.grid.2x2")
                    } description: {
                        Text("Make a section for anything you want to keep an eye on, like 🎮 Video Games or ☕️ Coffee.")
                    } actions: {
                        Button("Create a Tracker") { showingNew = true }.buttonStyle(.borderedProminent)
                    }
                }
            }
            .navigationTitle("Trackers")
            .toolbar {
                Button { showingNew = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add tracker")
            }
            .sheet(isPresented: $showingNew) { TrackerForm() }
        }
    }
}

struct TrackerRow: View {
    let tracker: Tracker

    var body: some View {
        let month = tracker.spent()
        HStack(spacing: 12) {
            EmojiBadge(emoji: tracker.emoji, color: Palette.color(tracker.colorName))
            VStack(alignment: .leading, spacing: 4) {
                Text(tracker.name).font(.headline)
                if let budget = tracker.monthlyBudget, budget > 0 {
                    ProgressView(value: min(month.double / budget.double, 1))
                        .tint(month > budget ? .red : Palette.color(tracker.colorName))
                    Text("\(month.currency) of \(budget.currency) this month")
                        .font(.caption).foregroundStyle(month > budget ? .red : .secondary)
                } else {
                    Text("\(month.currency) this month · \(tracker.totalSpent.currency) total")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct TrackerDetailView: View {
    @Environment(\.modelContext) private var context
    let tracker: Tracker

    @State private var addingEntry = false
    @State private var editingEntry: LedgerEntry?
    @State private var editingTracker = false

    private var monthly: [(month: Date, value: Double)] {
        let cal = Calendar.current
        return cal.recentMonths(6).map { month in
            (month, tracker.expenses.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }.sum(\.amount).double)
        }
    }

    var body: some View {
        let color = Palette.color(tracker.colorName)
        let month = tracker.spent()
        List {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        EmojiBadge(emoji: tracker.emoji, color: color, size: 56)
                        VStack(alignment: .leading) {
                            Text("This month").font(.subheadline).foregroundStyle(.secondary)
                            Text(month.currency).font(.title.bold()).monospacedDigit()
                        }
                    }
                    if let budget = tracker.monthlyBudget, budget > 0 {
                        ProgressView(value: min(month.double / budget.double, 1))
                            .tint(month > budget ? .red : color)
                        Text(month > budget
                             ? "\((month - budget).currency) over your \(budget.currency) budget"
                             : "\((budget - month).currency) left of \(budget.currency)")
                            .font(.caption).foregroundStyle(month > budget ? .red : .secondary)
                    }
                    HStack {
                        Text("All time: \(tracker.totalSpent.currency)")
                        Spacer()
                        Text("\(tracker.expenses.count) purchases")
                    }
                    .font(.subheadline).foregroundStyle(.secondary)

                    if !tracker.expenses.isEmpty {
                        Chart(monthly, id: \.month) { item in
                            BarMark(x: .value("Month", item.month, unit: .month),
                                    y: .value("Spent", item.value))
                                .foregroundStyle(color.gradient)
                                .cornerRadius(4)
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .month)) { _ in
                                AxisValueLabel(format: .dateTime.month(.abbreviated))
                            }
                        }
                        .frame(height: 140)
                    }
                }
                .padding(.vertical, 6)
            }

            Section("Purchases") {
                if tracker.sortedEntries.isEmpty {
                    Text("Nothing logged yet").foregroundStyle(.secondary)
                }
                ForEach(tracker.sortedEntries) { entry in
                    Button { editingEntry = entry } label: { EntryRow(entry: entry) }
                        .buttonStyle(.plain)
                }
                .onDelete { offsets in
                    let items = tracker.sortedEntries
                    for i in offsets { context.delete(items[i]) }
                }
            }
        }
        .navigationTitle(tracker.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { addingEntry = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add purchase")
            }
            ToolbarItem(placement: .secondaryAction) {
                Button("Edit Tracker") { editingTracker = true }
            }
        }
        .sheet(isPresented: $addingEntry) { EntryForm(tracker: tracker, kind: .expense) }
        .sheet(item: $editingEntry) { EntryForm(entry: $0) }
        .sheet(isPresented: $editingTracker) { TrackerForm(tracker: tracker) }
    }
}

struct TrackerForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let tracker: Tracker?

    @State private var name: String
    @State private var emoji: String
    @State private var colorName: String
    @State private var category: String
    @State private var budgetText: String

    init(tracker: Tracker? = nil) {
        self.tracker = tracker
        _name = State(initialValue: tracker?.name ?? "")
        _emoji = State(initialValue: tracker?.emoji ?? "🎮")
        _colorName = State(initialValue: tracker?.colorName ?? "purple")
        _category = State(initialValue: tracker?.defaultCategory ?? "Games")
        _budgetText = State(initialValue: tracker?.monthlyBudget.map(Money.editText) ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, e.g. Video Games", text: $name)
                    EmojiField(emoji: $emoji)
                    ColorChooser(selection: $colorName)
                }
                Section {
                    Picker("Default category", selection: $category) {
                        ForEach(Categories.expense, id: \.name) { Label($0.name, systemImage: $0.symbol).tag($0.name) }
                    }
                    AmountField(title: "Monthly budget", text: $budgetText)
                } footer: {
                    Text("The budget is optional. Leave it empty to just track what you spend.")
                }
            }
            .navigationTitle(tracker == nil ? "New Tracker" : "Edit Tracker")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let budget = Money.parse(budgetText).flatMap { $0 > 0 ? $0 : nil }
        let finalEmoji = emoji.isEmpty ? "📦" : emoji
        if let tracker {
            tracker.name = trimmed
            tracker.emoji = finalEmoji
            tracker.colorName = colorName
            tracker.defaultCategory = category
            tracker.monthlyBudget = budget
        } else {
            context.insert(Tracker(name: trimmed, emoji: finalEmoji, colorName: colorName,
                                   defaultCategory: category, monthlyBudget: budget))
        }
        dismiss()
    }
}
