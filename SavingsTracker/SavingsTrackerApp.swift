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
    @AppStorage(Theme.accentKey) private var accent = "default"
    @AppStorage(Theme.appearanceKey) private var appearance = Theme.Appearance.system
    @State private var tab = ContentView.initialTab
    @State private var showingSettings = false

    var body: some View {
        TabView(selection: $tab) {
            Tab("Overview", systemImage: "chart.pie", value: 0) { OverviewView() }
            Tab("Activity", systemImage: "list.bullet", value: 1) { TransactionsView().reveal() }
            Tab("Goals", systemImage: "target", value: 2) { GoalsView().reveal() }
            Tab("Trackers", systemImage: "square.grid.2x2", value: 3) { TrackersView().reveal() }
            Tab("Accounts", systemImage: "building.columns", value: 4) { AccountsView().reveal() }
        }
        .sensoryFeedback(.selection, trigger: tab)
        .id(currency + accent)
        .environment(\.showSettings, { showingSettings = true })
        // Outside the rebuilt tree, so changing currency or accent doesn't close Settings.
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .tint(Theme.accent(accent))
        .preferredColorScheme(appearance.colorScheme)
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
