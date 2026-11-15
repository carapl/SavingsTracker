import SwiftUI
import SwiftData
import Charts

struct OverviewView: View {
    @Query private var accounts: [Account]
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \SavingsGoal.createdAt) private var goals: [SavingsGoal]
    @Query(sort: \Tracker.createdAt) private var trackers: [Tracker]

    @State private var showingNewEntry = false
    @State private var showingSettings = false

    private var thisMonth: [LedgerEntry] {
        entries.filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .month) }
    }

    var body: some View {
        let income = thisMonth.filter { $0.kind == .income }.sum(\.amount)
        let spent = thisMonth.filter { $0.kind == .expense }.sum(\.amount)

        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if !accounts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total balance").font(.subheadline).foregroundStyle(.secondary)
                            Text(accounts.sum(\.balance).currency).font(.largeTitle.bold()).monospacedDigit()
                            Text("Across \(accounts.count) account\(accounts.count == 1 ? "" : "s")")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        .card()
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(Date.now, format: .dateTime.month(.wide)).font(.headline)
                        HStack {
                            Stat(title: "In", value: income, color: .green)
                            Stat(title: "Out", value: spent, color: .red)
                            Stat(title: "Saved", value: income - spent, color: income - spent >= 0 ? .accentColor : .red)
                        }
                    }
                    .card()

                    MonthlyChart(entries: entries).card()
                    CategoryChart(entries: thisMonth.filter { $0.kind == .expense }).card()

                    if !goals.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Goals").font(.headline)
                            ForEach(goals) { goal in
                                NavigationLink { GoalDetailView(goal: goal) } label: { GoalRow(goal: goal) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .card()
                    }

                    if !trackers.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Trackers").font(.headline)
                            ForEach(trackers) { tracker in
                                NavigationLink { TrackerDetailView(tracker: tracker) } label: { TrackerRow(tracker: tracker) }
                                    .buttonStyle(.plain)
                            }
                        }
                        .card()
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Overview")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                        .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .primaryAction) {
                    Button { showingNewEntry = true } label: { Image(systemName: "plus") }
                        .accessibilityLabel("Add transaction")
                }
            }
            .sheet(isPresented: $showingNewEntry) { EntryForm() }
            .sheet(isPresented: $showingSettings) { SettingsView() }
        }
    }
}

private struct Stat: View {
    let title: String
    let value: Decimal
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value.currency)
                .font(.headline).monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct MonthlyChart: View {
    let entries: [LedgerEntry]

    private struct Point: Identifiable {
        let month: Date
        let series: String
        let value: Double
        var id: String { "\(month.timeIntervalSince1970)-\(series)" }
    }

    private var points: [Point] {
        let cal = Calendar.current
        return cal.recentMonths(6).flatMap { month -> [Point] in
            let items = entries.filter { cal.isDate($0.date, equalTo: month, toGranularity: .month) }
            return [
                Point(month: month, series: "Income", value: items.filter { $0.kind == .income }.sum(\.amount).double),
                Point(month: month, series: "Expenses", value: items.filter { $0.kind == .expense }.sum(\.amount).double),
            ]
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 6 months").font(.headline)
            if entries.isEmpty {
                Text("Log some income and expenses to see your trend here.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 80)
            } else {
                Chart(points) { point in
                    BarMark(x: .value("Month", point.month, unit: .month),
                            y: .value("Amount", point.value))
                        .foregroundStyle(by: .value("Type", point.series))
                        .position(by: .value("Type", point.series))
                        .cornerRadius(3)
                }
                .chartForegroundStyleScale(["Income": Color.green, "Expenses": Color.red.opacity(0.8)])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month)) { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .frame(height: 200)
            }
        }
    }
}

private struct CategoryChart: View {
    let entries: [LedgerEntry]

    private var totals: [(category: String, value: Decimal)] {
        Dictionary(grouping: entries, by: \.category)
            .map { ($0.key, $0.value.sum(\.amount)) }
            .sorted { $0.value > $1.value }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Spending this month").font(.headline)
            if totals.isEmpty {
                Text("No expenses logged this month.")
                    .font(.subheadline).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 60)
            } else {
                HStack(alignment: .center, spacing: 16) {
                    Chart(totals, id: \.category) { item in
                        SectorMark(angle: .value("Spent", item.value.double),
                                   innerRadius: .ratio(0.6), angularInset: 1.5)
                            .foregroundStyle(by: .value("Category", item.category))
                            .cornerRadius(3)
                    }
                    .chartLegend(.hidden)
                    .frame(width: 130, height: 130)

                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(totals.prefix(5), id: \.category) { item in
                            HStack {
                                Label(item.category, systemImage: Categories.symbol(for: item.category))
                                    .font(.subheadline)
                                Spacer()
                                Text(item.value.currency).font(.subheadline).monospacedDigit()
                            }
                        }
                    }
                }
            }
        }
    }
}
