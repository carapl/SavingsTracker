import SwiftUI
import SwiftData
import Charts

/// Full list of this week's tips, with a summary of the last 6 weeks.
struct WeeklyTipsView: View {
    @Query(sort: \LedgerEntry.date, order: .reverse) private var entries: [LedgerEntry]
    @Query(sort: \SavingsGoal.createdAt) private var goals: [SavingsGoal]
    @Query(sort: \Tracker.createdAt) private var trackers: [Tracker]

    var body: some View {
        let summary = WeeklyTips.summary(entries)
        let tips = WeeklyTips.tips(entries: entries, goals: goals, trackers: trackers)

        ScrollView {
            VStack(spacing: 16) {
                WeekSummaryCard(summary: summary).card().reveal(0)
                ForEach(Array(tips.enumerated()), id: \.element.id) { index, tip in
                    TipRow(tip: tip).card().reveal(min(index + 1, 8))
                }
                Text("Rent, bills and subscriptions are left out when comparing weeks, since they arrive once a month.")
                    .font(.footnote).foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 4)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Weekly Tips")
    }
}

private struct WeekSummaryCard: View {
    let summary: WeeklyTips.Summary
    @State private var grow = 0.0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Spent in the last 7 days").font(.subheadline).foregroundStyle(.secondary)
                AmountText(summary.thisWeek).font(.largeTitle.bold()).monospacedDigit()
                if let usual = summary.usualWeek, usual > 0 {
                    let change = ((summary.thisWeek - usual) / usual).double
                    HStack(spacing: 6) {
                        Image(systemName: change > 0 ? "arrow.up.right" : "arrow.down.right")
                        Text("\(Int((abs(change) * 100).rounded()))% vs your usual \(usual.currency)")
                    }
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(change > 0.15 ? .orange : change < -0.1 ? .green : .secondary)
                }
            }
            if summary.weeks.contains(where: { $0.spent > 0 }) {
                let top = max(summary.weeks.map(\.spent.double).max() ?? 0, 1)
                Chart(summary.weeks) { week in
                    BarMark(x: .value("Week", week.start, unit: .weekOfYear),
                            y: .value("Spent", week.spent.double * grow))
                        .foregroundStyle(week.id == summary.weeks.last?.id ? Theme.accent : Color.secondary.opacity(0.35))
                        .cornerRadius(4)
                }
                .chartYScale(domain: 0...top * 1.05)
                .chartYAxis(.hidden)
                .chartXAxis {
                    AxisMarks(values: summary.weeks.map(\.start)) { _ in
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                    }
                }
                .frame(height: 110)
                .modifier(GrowOnAppear(progress: $grow))
            }
        }
    }
}

struct TipRow: View {
    let tip: Tip
    var compact = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: tip.symbol)
                .font(.system(size: compact ? 14 : 16, weight: .semibold))
                .foregroundStyle(tip.color)
                .frame(width: compact ? 30 : 36, height: compact ? 30 : 36)
                .background(tip.color.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(tip.title).font(compact ? .subheadline.weight(.semibold) : .headline)
                Text(tip.message)
                    .font(compact ? .footnote : .subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(compact ? 3 : nil)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
    }
}

/// The top tips, shown on Overview.
struct TipsCard: View {
    let entries: [LedgerEntry]
    let goals: [SavingsGoal]
    let trackers: [Tracker]

    var body: some View {
        let tips = WeeklyTips.tips(entries: entries, goals: goals, trackers: trackers)
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Weekly tips", systemImage: "lightbulb.fill")
                    .font(.headline)
                    .labelStyle(TintedIconLabel())
                Spacer()
                NavigationLink { WeeklyTipsView() } label: {
                    HStack(spacing: 2) { Text("See all"); Image(systemName: "chevron.right").font(.caption.weight(.semibold)) }
                        .font(.subheadline)
                }
            }
            ForEach(tips.prefix(2)) { tip in TipRow(tip: tip, compact: true) }
        }
    }
}

private struct TintedIconLabel: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            configuration.icon.foregroundStyle(.yellow)
            configuration.title
        }
    }
}
