import SwiftUI
import SwiftData
import CryptoKit
import UserNotifications

/// Gate for the advanced tools. Only a salted, stretched hash of the code is stored,
/// never the code itself.
enum AdvancedAccess {
    static let unlockedKey = "advancedUnlocked"
    private static let lockUntilKey = "advancedLockedUntil"
    private static let failuresKey = "advancedFailures"

    private static let salt = "0421671107a1fb1e812c4b2be8158583"
    private static let expected = "0fb8d53a43415dd25f345bf1c3fdfd4d6776afa065c30ef791976892d95966f3"
    private static let rounds = 150_000

    static var isUnlocked: Bool { UserDefaults.standard.bool(forKey: unlockedKey) }

    /// Seconds left before another attempt is allowed, after too many wrong codes.
    static var waitSeconds: Int {
        let until = UserDefaults.standard.double(forKey: lockUntilKey)
        return max(Int((until - Date.now.timeIntervalSince1970).rounded(.up)), 0)
    }

    static func derive(_ code: String) -> String {
        let saltBytes = Array(salt.utf8)
        var digest = Array(SHA256.hash(data: saltBytes + Array(code.utf8)))
        for _ in 0..<rounds { digest = Array(SHA256.hash(data: digest + saltBytes)) }
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    /// Checks the code off the main thread. Three wrong tries lock it for a minute.
    static func verify(_ code: String) async -> Bool {
        guard waitSeconds == 0 else { return false }
        let ok = await Task.detached(priority: .userInitiated) { derive(code) == expected }.value
        let store = UserDefaults.standard
        if ok {
            store.set(0, forKey: failuresKey)
            store.set(true, forKey: unlockedKey)
        } else {
            let failures = store.integer(forKey: failuresKey) + 1
            store.set(failures, forKey: failuresKey)
            if failures >= 3 {
                store.set(0, forKey: failuresKey)
                store.set(Date.now.timeIntervalSince1970 + 60, forKey: lockUntilKey)
            }
        }
        return ok
    }

    static func lock() { UserDefaults.standard.set(false, forKey: unlockedKey) }
}

/// The switch at the bottom of Settings that asks for the code.
struct AdvancedToggleSection: View {
    /// Closes the Settings sheet, so the intro can be shown.
    let closeSettings: () -> Void
    @AppStorage(AdvancedAccess.unlockedKey) private var unlocked = false
    @State private var asking = false
    @State private var code = ""
    @State private var checking = false
    @State private var error: String?

    var body: some View {
        Section {
            Toggle(isOn: Binding(get: { unlocked || asking }, set: { on in
                if on { code = ""; error = nil; asking = true } else { AdvancedAccess.lock() }
            })) {
                HStack {
                    Label("Developer mode", systemImage: "hammer")
                    if checking { Spacer(); ProgressView() }
                }
            }
            if unlocked {
                NavigationLink { AdvancedView(closeSettings: closeSettings) } label: {
                    Label("Developer tools", systemImage: "wrench.and.screwdriver")
                }
            }
            if let error {
                Text(error).font(.footnote).foregroundStyle(.red)
            }
        }
        .alert("Enter code", isPresented: $asking) {
            SecureField("Code", text: $code)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            Button("Cancel", role: .cancel) { code = "" }
            Button("Unlock") { check() }
        } message: {
            Text("Developer mode is for testing the app.")
        }
    }

    private func check() {
        let attempt = code
        code = ""
        let wait = AdvancedAccess.waitSeconds
        guard wait == 0 else { error = "Too many tries. Wait \(wait) s."; return }
        checking = true
        Task {
            let ok = await AdvancedAccess.verify(attempt)
            checking = false
            withAnimation { error = ok ? nil : "Wrong code." }
            if ok { UINotificationFeedbackGenerator().notificationOccurred(.success) }
            else { UINotificationFeedbackGenerator().notificationOccurred(.error) }
        }
    }
}

/// Tools for testing the app on a real phone.
struct AdvancedView: View {
    let closeSettings: () -> Void
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    @Query private var entries: [LedgerEntry]
    @Query private var goals: [SavingsGoal]
    @Query private var trackers: [Tracker]
    @AppStorage(Motion.slowKey) private var slowAnimations = false
    @AppStorage(Profile.onboardedKey) private var onboarded = true

    // Auto-log tester
    @State private var testAmount = "27.90"
    @State private var testMerchant = "47 Paralel Nr 1 Spataru"
    @State private var testCard = ""
    @State private var testResult: String?

    @State private var introStep = 0
    @State private var pending = 0
    @State private var notice: String?
    @State private var confirmingWipe = false

    var body: some View {
        Form {
            Section {
                TextField("Merchant", text: $testMerchant)
                LabeledContent("Category", value: MerchantRules.category(for: testMerchant))
                AmountField(title: "Amount", text: $testAmount)
                TextField("Card name (as Wallet sends it)", text: $testCard)
                    .autocorrectionDisabled()
                LabeledContent("Goes to", value: matchedAccountName)
                Button("Log Test Payment") {
                    let amount = (Money.parse(testAmount) ?? 0).double
                    testResult = (try? AutoLogger.log(amount: amount, merchant: testMerchant, card: testCard)) ?? "Failed to save."
                }
                if let testResult {
                    Text(testResult).font(.footnote).foregroundStyle(.secondary)
                }
            } header: {
                Text("Apple Pay auto-log")
            } footer: {
                Text("Runs exactly what the Shortcuts action does. It saves a real transaction; swipe it away in Activity afterwards.")
            }

            Section("Intro") {
                Picker("Start at", selection: $introStep) {
                    ForEach(OnboardingView.Step.allCases, id: \.rawValue) { Text("\($0)".capitalized).tag($0.rawValue) }
                }
                Button("Show Intro") {
                    UserDefaults.standard.set(introStep, forKey: OnboardingView.startStepKey)
                    closeSettings()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { onboarded = false }
                }
            }

            Section {
                NavigationLink("Open Weekly Tips") { WeeklyTipsView() }
                Button("Send Tips Notification in 5 s") { sendTestNotification() }
                LabeledContent("Scheduled reminders", value: "\(pending)")
                Button("Reschedule Weekly Reminder") {
                    TipsReminder.sync()
                    refreshPending()
                    notice = Profile.tipsEnabled ? "Scheduled for \(Calendar.current.weekdaySymbols[Profile.tipsWeekday - 1]) \(Profile.tipsHour):00." : "Weekly tips are off in Settings."
                }
            } header: {
                Text("Weekly tips")
            } footer: {
                Text("Lock the phone after sending the test to see it as a real notification.")
            }

            Section("Look and feel") {
                Toggle("Slow animations (×4)", isOn: $slowAnimations)
            }

            Section {
                LabeledContent("Accounts", value: "\(accounts.count)")
                LabeledContent("Transactions", value: "\(entries.count) (\(entries.filter(\.isAutoLogged).count) automatic)")
                LabeledContent("Goals", value: "\(goals.count)")
                LabeledContent("Trackers", value: "\(trackers.count)")
                LabeledContent("Unlinked Wallet cards", value: "\(UnlinkedCards.all.count)")
                Button("Clear Unlinked Wallet Cards") {
                    UserDefaults.standard.removeObject(forKey: UnlinkedCards.key)
                    notice = "Cleared."
                }
                Button("Load Demo Data") {
                    SampleData.insertIfEmpty()
                    notice = "Demo data loaded."
                }
                .disabled(!entries.isEmpty || !accounts.isEmpty)
                Button("Delete All Data", role: .destructive) { confirmingWipe = true }
            } header: {
                Text("Data")
            } footer: {
                Text("Demo data only loads into an empty app. Save a backup before deleting anything.")
            }

            Section("Stored settings") {
                ForEach(storedValues, id: \.0) { key, value in
                    LabeledContent(key) { Text(value).font(.footnote.monospaced()).lineLimit(2) }
                }
            }

            Section("App") {
                LabeledContent("Version", value: "\(info("CFBundleShortVersionString")) (\(info("CFBundleVersion")))")
                LabeledContent("Bundle", value: Bundle.main.bundleIdentifier ?? "–")
                LabeledContent("iOS", value: UIDevice.current.systemVersion)
                #if DEBUG
                LabeledContent("Build", value: "Debug")
                #else
                LabeledContent("Build", value: "Release")
                #endif
            }

            Section {
                Button("Lock Developer Mode") {
                    AdvancedAccess.lock()
                    dismiss()
                }
            }
        }
        .navigationTitle("Developer")
        .navigationBarTitleDisplayMode(.inline)
        .task { refreshPending() }
        .alert(notice ?? "", isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Button("OK", role: .cancel) {}
        }
        .confirmationDialog("Delete every account, transaction, goal and tracker?", isPresented: $confirmingWipe, titleVisibility: .visible) {
            Button("Delete All Data", role: .destructive, action: wipe)
        }
    }

    private var matchedAccountName: String {
        if let account = CardMatcher.account(for: testCard, in: accounts) { return account.name }
        if let fallback = accounts.first(where: \.isDefaultForAutoLog) { return "\(fallback.name) (default)" }
        return accounts.count == 1 ? accounts[0].name : "No account"
    }

    private var storedValues: [(String, String)] {
        let store = UserDefaults.standard
        return [Money.codeKey, Profile.nameKey, Profile.incomeKey, Profile.paydayKey, Profile.savingsPercentKey,
                Profile.watchedKey, Profile.tipsEnabledKey, Profile.tipsWeekdayKey, Profile.onboardedKey,
                Theme.appearanceKey, Theme.accentKey]
            .map { ($0, store.object(forKey: $0).map { "\($0)" } ?? "–") }
    }

    private func info(_ key: String) -> String { Bundle.main.object(forInfoDictionaryKey: key) as? String ?? "–" }

    private func refreshPending() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            DispatchQueue.main.async { pending = requests.count }
        }
    }

    private func sendTestNotification() {
        Task {
            let center = UNUserNotificationCenter.current()
            guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else {
                notice = "Notifications are off for Savings in iPhone Settings."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Your weekly money tips are ready"
            content.body = "See how this week went and what to tweak for the next one."
            content.sound = .default
            content.userInfo = ["route": "tips"]
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: "weekly-tips-test", content: content, trigger: trigger))
            notice = "Sent. It arrives in 5 seconds."
        }
    }

    private func wipe() {
        try? context.delete(model: LedgerEntry.self)
        try? context.delete(model: GoalDeposit.self)
        try? context.delete(model: SavingsGoal.self)
        try? context.delete(model: Tracker.self)
        try? context.delete(model: Account.self)
        try? context.save()
        UserDefaults.standard.removeObject(forKey: UnlinkedCards.key)
        notice = "All data deleted."
    }
}
