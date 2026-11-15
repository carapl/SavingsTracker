import SwiftUI
import SwiftData

struct TransactionsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]

    @State private var filter: Filter = .all
    @State private var search = ""
    @State private var showingNew = false
    @State private var editing: LedgerEntry?

    enum Filter: String, CaseIterable, Identifiable {
        case all = "All", income = "Income", expense = "Expenses"
        var id: Self { self }
    }

    private var filtered: [LedgerEntry] {
        entries.filter { entry in
            switch filter {
            case .all: break
            case .income: if entry.kind != .income { return false }
            case .expense: if entry.kind != .expense { return false }
            }
            guard !search.isEmpty else { return true }
            return entry.category.localizedCaseInsensitiveContains(search)
                || entry.note.localizedCaseInsensitiveContains(search)
                || (entry.tracker?.name.localizedCaseInsensitiveContains(search) ?? false)
        }
    }

    private var months: [(month: Date, items: [LedgerEntry])] {
        let cal = Calendar.current
        return Dictionary(grouping: filtered) { cal.monthStart($0.date) }
            .map { ($0.key, $0.value) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        NavigationStack {
            List {
                Picker("Filter", selection: $filter) {
                    ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())

                ForEach(months, id: \.month) { group in
                    Section {
                        ForEach(group.items) { entry in
                            Button { editing = entry } label: { EntryRow(entry: entry) }
                                .buttonStyle(.plain)
                        }
                        .onDelete { offsets in
                            for i in offsets { context.delete(group.items[i]) }
                        }
                    } header: {
                        HStack {
                            Text(group.month, format: .dateTime.month(.wide).year())
                            Spacer()
                            Text(group.items.sum(\.signedAmount).currency)
                        }
                    }
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView("No transactions yet",
                                           systemImage: "list.bullet.rectangle",
                                           description: Text("Tap + to log income or an expense."))
                } else if filtered.isEmpty {
                    ContentUnavailableView.search(text: search)
                }
            }
            .searchable(text: $search, prompt: "Category, note or tracker")
            .navigationTitle("Activity")
            .toolbar {
                Button { showingNew = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add transaction")
            }
            .sheet(isPresented: $showingNew) { EntryForm() }
            .sheet(item: $editing) { EntryForm(entry: $0) }
        }
    }
}

struct EntryRow: View {
    let entry: LedgerEntry
    var showDate = true

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: Categories.symbol(for: entry.category))
                .frame(width: 36, height: 36)
                .foregroundStyle(entry.kind == .income ? .green : .accentColor)
                .background((entry.kind == .income ? Color.green : Color.accentColor).opacity(0.15), in: Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? entry.category : entry.note)
                    .lineLimit(1)
                HStack(spacing: 4) {
                    if !entry.note.isEmpty { Text(entry.category) }
                    if let tracker = entry.tracker { Text("· \(tracker.emoji) \(tracker.name)") }
                    if showDate { Text("· \(entry.date.formatted(.dateTime.day().month()))") }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }

            Spacer()

            Text((entry.kind == .income ? "+" : "−") + entry.amount.currency)
                .monospacedDigit()
                .foregroundStyle(entry.kind == .income ? .green : .primary)
        }
        .contentShape(Rectangle())
    }
}

struct EntryForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Account.name) private var accounts: [Account]
    @Query(sort: \Tracker.name) private var trackers: [Tracker]

    private let entry: LedgerEntry?
    @State private var kind: TransactionKind
    @State private var amountText: String
    @State private var category: String
    @State private var date: Date
    @State private var note: String
    @State private var account: Account?
    @State private var tracker: Tracker?
    @State private var confirmDelete = false

    init(entry: LedgerEntry? = nil, tracker: Tracker? = nil, kind: TransactionKind = .expense) {
        self.entry = entry
        let k = entry?.kind ?? kind
        _kind = State(initialValue: k)
        _amountText = State(initialValue: entry.map { Money.editText($0.amount) } ?? "")
        _category = State(initialValue: entry?.category ?? tracker?.defaultCategory ?? Categories.list(for: k)[0].name)
        _date = State(initialValue: entry?.date ?? .now)
        _note = State(initialValue: entry?.note ?? "")
        _account = State(initialValue: entry?.account)
        _tracker = State(initialValue: entry?.tracker ?? tracker)
    }

    private var amount: Decimal? {
        guard let value = Money.parse(amountText), value > 0 else { return nil }
        return value
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $kind) {
                        ForEach(TransactionKind.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    AmountField(title: "Amount", text: $amountText)
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(Categories.list(for: kind), id: \.name) { item in
                            Label(item.name, systemImage: item.symbol).tag(item.name)
                        }
                    }
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Note (optional)", text: $note)
                }

                Section {
                    Picker("Account", selection: $account) {
                        Text("None").tag(Account?.none)
                        ForEach(accounts) { Text($0.name).tag(Optional($0)) }
                    }
                    if kind == .expense {
                        Picker("Tracker", selection: $tracker) {
                            Text("None").tag(Tracker?.none)
                            ForEach(trackers) { Text("\($0.emoji) \($0.name)").tag(Optional($0)) }
                        }
                    }
                } footer: {
                    Text(kind == .expense
                         ? "Linking an account updates its balance. Add the expense to a tracker to follow spending on one thing, like video games."
                         : "Linking an account updates its balance.")
                }

                if entry != nil {
                    Section {
                        Button("Delete Transaction", role: .destructive) { confirmDelete = true }
                    }
                }
            }
            .onChange(of: kind) { _, newKind in
                if !Categories.list(for: newKind).contains(where: { $0.name == category }) {
                    category = Categories.list(for: newKind)[0].name
                }
            }
            .navigationTitle(entry == nil ? "New Transaction" : "Edit Transaction")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save).disabled(amount == nil)
                }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    if let entry { context.delete(entry) }
                    dismiss()
                }
            }
        }
    }

    private func save() {
        guard let amount else { return }
        let target: LedgerEntry
        if let entry {
            target = entry
        } else {
            target = LedgerEntry(amount: amount, kind: kind, category: category)
            context.insert(target)
        }
        target.amount = amount
        target.kind = kind
        target.category = category
        target.date = date
        target.note = note.trimmingCharacters(in: .whitespaces)
        target.account = account
        target.tracker = kind == .expense ? tracker : nil
        dismiss()
    }
}
