import SwiftUI
import SwiftData

@main
struct SavingsTrackerApp: App {
    init() {
        #if DEBUG
        SampleData.insertIfRequested()
        #endif
    }

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
    @State private var tab = ContentView.initialTab

    var body: some View {
        TabView(selection: $tab) {
            Tab("Overview", systemImage: "chart.pie", value: 0) { OverviewView() }
            Tab("Activity", systemImage: "list.bullet", value: 1) { TransactionsView() }
            Tab("Goals", systemImage: "target", value: 2) { GoalsView() }
            Tab("Trackers", systemImage: "square.grid.2x2", value: 3) { TrackersView() }
            Tab("Accounts", systemImage: "building.columns", value: 4) { AccountsView() }
        }
        .id(currency)
    }

    /// Debug builds accept `-tab N` at launch (used for README screenshots).
    private static var initialTab: Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let n = Int(args[i + 1]) { return n }
        #endif
        return 0
    }
}
