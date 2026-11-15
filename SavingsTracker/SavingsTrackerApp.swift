import SwiftUI
import SwiftData

@main
struct SavingsTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // The default configuration syncs through CloudKit automatically
        // once the iCloud capability is added to the target.
        .modelContainer(AppData.container)
    }
}

struct ContentView: View {
    // Rebuild every screen when the currency changes so all amounts redraw.
    @AppStorage(Money.codeKey) private var currency = Money.defaultCode

    var body: some View {
        TabView {
            Tab("Overview", systemImage: "chart.pie") { OverviewView() }
            Tab("Activity", systemImage: "list.bullet") { TransactionsView() }
            Tab("Goals", systemImage: "target") { GoalsView() }
            Tab("Trackers", systemImage: "square.grid.2x2") { TrackersView() }
            Tab("Accounts", systemImage: "building.columns") { AccountsView() }
        }
        .id(currency)
    }
}
