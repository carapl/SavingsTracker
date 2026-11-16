import SwiftUI
import SwiftData

@main
struct SavingsTrackerApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        #if DEBUG
        // -resetOnboarding shows the intro again; -skipOnboarding or -sampleData hide it (README screenshots).
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetOnboarding") { UserDefaults.standard.set(false, forKey: Profile.onboardedKey) }
        if args.contains("-skipOnboarding") || args.contains("-sampleData") {
            UserDefaults.standard.set(true, forKey: Profile.onboardedKey)
        }
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
    @AppStorage(Profile.onboardedKey) private var onboarded = false
    @Bindable private var router = TipsRouter.shared

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
        .sheet(isPresented: $router.showTips) {
            NavigationStack {
                WeeklyTipsView().toolbar { Button("Done") { router.showTips = false } }
            }
        }
        #if DEBUG
        // -helpTopic <id> opens that help page at launch, for checking the animations.
        .sheet(item: Binding(get: { ContentView.debugHelpTopic }, set: { _ in ContentView.debugHelpTopic = nil })) { topic in
            NavigationStack { HelpTopicView(topic: topic) }
        }
        #endif
        .fullScreenCover(isPresented: Binding(get: { !onboarded }, set: { onboarded = !$0 })) {
            OnboardingView()
                .tint(Theme.accent(accent))
                .preferredColorScheme(appearance.colorScheme)
        }
        .tint(Theme.accent(accent))
        .preferredColorScheme(appearance.colorScheme)
    }

    #if DEBUG
    nonisolated(unsafe) static var debugHelpTopic: HelpTopic? = {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-helpTopic"), i + 1 < args.count else { return nil }
        return HelpContent.all.first { $0.id == args[i + 1] }
    }()
    #endif

    /// Debug builds accept `-tab N` at launch (used for README screenshots).
    private static var initialTab: Int {
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-tab"), i + 1 < args.count, let n = Int(args[i + 1]) { return n }
        #endif
        return 0
    }
}
