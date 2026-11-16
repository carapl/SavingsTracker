import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(Money.codeKey) private var currency = Money.defaultCode
    @AppStorage(Theme.appearanceKey) private var appearance = Theme.Appearance.system
    @AppStorage(Theme.accentKey) private var accent = "default"
    @Query(sort: \Account.createdAt) private var accounts: [Account]
    @AppStorage(Profile.nameKey) private var name = ""
    @AppStorage(Profile.incomeKey) private var income = 0.0
    @AppStorage(Profile.paydayKey) private var payday = 0
    @AppStorage(Profile.savingsPercentKey) private var savingsPercent = Profile.defaultSavingsPercent
    @AppStorage(Profile.watchedKey) private var watched = ""
    @AppStorage(Profile.tipsEnabledKey) private var tipsEnabled = false
    @AppStorage(Profile.tipsWeekdayKey) private var tipsWeekday = Profile.defaultTipsWeekday
    @AppStorage(Profile.onboardedKey) private var onboarded = true
    @State private var incomeText = Profile.monthlyIncome > 0 ? Money.editText(Profile.monthlyIncome) : ""
    @State private var notificationsBlocked = false

    private var defaultAccount: Binding<Account?> {
        Binding(
            get: { accounts.first { $0.isDefaultForAutoLog } },
            set: { chosen in
                for account in accounts { account.isDefaultForAutoLog = (account === chosen) }
            }
        )
    }

    @State private var backupURL: URL?
    @State private var csvURL: URL?
    @State private var exportError: String?
    @State private var choosingFile = false
    @State private var pendingRestore: BackupFile?
    @State private var message: String?
    @State private var unlinkedCards = UnlinkedCards.all

    private func link(_ card: String, to account: Account) {
        for other in accounts { other.walletCardList.removeAll { $0.caseInsensitiveCompare(card) == .orderedSame } }
        account.walletCardList.append(card)
        // Move payments already logged with this card to the chosen account.
        let entries = (try? context.fetch(FetchDescriptor<LedgerEntry>())) ?? []
        for entry in entries where entry.isAutoLogged && entry.cardName.caseInsensitiveCompare(card) == .orderedSame {
            entry.account = account
        }
        forget(card)
    }

    private func forget(_ card: String) {
        UnlinkedCards.remove(card)
        unlinkedCards = UnlinkedCards.all
    }

    /// Also picks up cards from payments logged before this list existed.
    private func findUnlinkedCards() {
        let entries = (try? context.fetch(FetchDescriptor<LedgerEntry>())) ?? []
        for entry in entries where entry.isAutoLogged && !entry.cardName.isEmpty {
            let match = CardMatcher.account(for: entry.cardName, in: accounts)
            if match == nil || entry.account !== match { UnlinkedCards.add(entry.cardName) }
        }
        unlinkedCards = UnlinkedCards.all
    }

    private let popular = ["MDL", "RON", "EUR", "USD", "GBP"]
    private var others: [String] {
        Locale.commonISOCurrencyCodes.filter { !popular.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name", text: $name)
                    AmountField(title: "Monthly income", text: $incomeText)
                        .onChange(of: incomeText) { _, text in income = (Money.parse(text) ?? 0).double }
                    Picker("Payday", selection: $payday) {
                        Text("Varies").tag(0)
                        ForEach(1...31, id: \.self) { Text("\($0)").tag($0) }
                    }
                    Stepper(value: $savingsPercent, in: 5...50, step: 5) {
                        LabeledContent("Save each month") {
                            Text(Profile.monthlyIncome > 0 ? "\(savingsPercent)% · \(Profile.plannedSavings.currency)" : "\(savingsPercent)%")
                                .monospacedDigit()
                        }
                    }
                    NavigationLink {
                        WatchedCategoriesView(watched: $watched)
                    } label: {
                        LabeledContent("Keep an eye on", value: Profile.decodeList(watched).isEmpty ? "None" : Profile.decodeList(watched).joined(separator: ", "))
                    }
                } header: {
                    Text("Your plan")
                } footer: {
                    Text("Used for weekly tips and goal suggestions. Stays on this phone.")
                }

                Section {
                    Toggle("Weekly reminder", isOn: $tipsEnabled)
                        .onChange(of: tipsEnabled) { _, on in
                            guard on else { TipsReminder.cancel(); return }
                            Task {
                                if !(await TipsReminder.enable(weekday: tipsWeekday)) {
                                    tipsEnabled = false
                                    notificationsBlocked = true
                                }
                            }
                        }
                    if tipsEnabled {
                        Picker("Day", selection: $tipsWeekday) {
                            ForEach(1...7, id: \.self) { Text(Calendar.current.weekdaySymbols[$0 - 1]).tag($0) }
                        }
                        .onChange(of: tipsWeekday) { _, day in TipsReminder.schedule(weekday: day) }
                    }
                    if notificationsBlocked {
                        Button("Allow notifications in iPhone Settings") {
                            if let url = URL(string: UIApplication.openSettingsURLString) { UIApplication.shared.open(url) }
                        }
                    }
                } header: {
                    Text("Weekly tips")
                } footer: {
                    Text("A reminder at \(Profile.tipsHour):00 on the day you pick. Tips are always on Overview too.")
                }

                Section("Appearance") {
                    Picker("Theme", selection: $appearance) {
                        ForEach(Theme.Appearance.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .padding(.vertical, 4)
                }

                Section("Accent color") {
                    AccentChooser(selection: $accent)
                }

                Section("App icon") {
                    AppIconChooser()
                }

                Section {
                    Picker("Currency", selection: $currency) {
                        ForEach(popular, id: \.self) { Text("\(Money.name(for: $0)) (\($0))").tag($0) }
                        Divider()
                        ForEach(others, id: \.self) { Text("\(Money.name(for: $0)) (\($0))").tag($0) }
                    }
                } footer: {
                    Text("Changes how amounts are shown. Amounts you already saved keep their numbers; they aren't converted.")
                }

                Section {
                    Picker("Default account", selection: defaultAccount) {
                        Text("None").tag(Account?.none)
                        ForEach(accounts) { Text($0.name).tag(Optional($0)) }
                    }
                } header: {
                    Text("Automatic payments")
                } footer: {
                    Text("Payments go to the account whose name matches the card, like \"MAIB\" for a card called \"MAIB Visa\". If no name matches, they go to this account.")
                }

                Section {
                    ForEach(unlinkedCards, id: \.self) { card in
                        Menu {
                            ForEach(accounts) { account in
                                Button(account.name) { link(card, to: account) }
                            }
                        } label: {
                            LabeledContent {
                                Text("Link…").foregroundStyle(.tint)
                            } label: {
                                Label(card, systemImage: "creditcard.trianglebadge.exclamationmark")
                            }
                        }
                        .swipeActions { Button("Ignore", role: .destructive) { forget(card) } }
                    }
                    ForEach(accounts) { account in
                        ForEach(account.walletCardList, id: \.self) { card in
                            LabeledContent {
                                Text(account.name).foregroundStyle(.secondary)
                            } label: {
                                Label(card, systemImage: "creditcard")
                            }
                            .swipeActions { Button("Unlink", role: .destructive) { account.walletCardList.removeAll { $0 == card } } }
                        }
                    }
                    if unlinkedCards.isEmpty && accounts.allSatisfy({ $0.walletCardList.isEmpty }) {
                        Text("No cards yet. Pay once with Apple Pay and the card shows up here.")
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Text("Wallet cards")
                } footer: {
                    Text("Cards from your Wallet automation that didn't match an account appear here. Link one to send its payments, past and future, to that account.")
                }

                Section {
                    if let backupURL {
                        ShareLink(item: backupURL) {
                            Label("Save Backup", systemImage: "externaldrive.badge.checkmark")
                        }
                    }
                    if let csvURL {
                        ShareLink(item: csvURL) {
                            Label("Export Transactions (CSV)", systemImage: "tablecells")
                        }
                    }
                    if let exportError {
                        Text(exportError).foregroundStyle(.red)
                    }
                } header: {
                    Text("Export")
                } footer: {
                    Text("Save the backup to Files or iCloud Drive, or send it to yourself. The CSV opens in Numbers, Excel or Google Sheets.")
                }

                Section {
                    Button {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { onboarded = false }
                    } label: {
                        Label("Show Intro Again", systemImage: "sparkles")
                    }
                }

                Section {
                    Button { choosingFile = true } label: {
                        Label("Restore from Backup…", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("Restoring replaces everything currently in the app with the backup's contents.")
                }

                AdvancedToggleSection(closeSettings: { dismiss() })
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .task { prepareExports(); findUnlinkedCards() }
            .fileImporter(isPresented: $choosingFile, allowedContentTypes: [.json]) { result in
                do {
                    pendingRestore = try Backup.read(result.get())
                } catch {
                    message = "That file couldn't be read as a Savings backup."
                }
            }
            .confirmationDialog("Replace all data with this backup?",
                                isPresented: Binding(get: { pendingRestore != nil }, set: { if !$0 { pendingRestore = nil } }),
                                titleVisibility: .visible) {
                Button("Replace Everything", role: .destructive) {
                    guard let file = pendingRestore else { return }
                    do {
                        try Backup.restore(file, into: context)
                        message = "Restored \(file.entries.count) transactions, \(file.goals.count) goals, \(file.trackers.count) trackers and \(file.accounts.count) accounts."
                        prepareExports()
                    } catch {
                        message = "Restore failed: \(error.localizedDescription)"
                    }
                }
            } message: {
                if let file = pendingRestore {
                    Text("Backup from \(file.exportedAt.formatted(date: .abbreviated, time: .shortened)) with \(file.entries.count) transactions. What's in the app now will be deleted.")
                }
            }
            .alert(message ?? "", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
                Button("OK") {}
            }
        }
    }

    private func prepareExports() {
        do {
            backupURL = try Backup.makeBackup(context)
            csvURL = try Backup.makeCSV(context)
            exportError = nil
        } catch {
            exportError = "Couldn't prepare export: \(error.localizedDescription)"
        }
    }
}

/// Multi-select list of the categories weekly tips should report on.
private struct WatchedCategoriesView: View {
    @Binding var watched: String

    var body: some View {
        let selected = Set(Profile.decodeList(watched))
        List {
            Section {
                ForEach(Categories.expense.map(\.name).filter { $0 != "Other" }, id: \.self) { name in
                    Button {
                        var next = selected
                        if next.contains(name) { next.remove(name) } else { next.insert(name) }
                        watched = Profile.encodeList(Categories.expense.map(\.name).filter(next.contains))
                    } label: {
                        HStack {
                            Label(name, systemImage: Categories.symbol(for: name)).foregroundStyle(.primary)
                            Spacer()
                            if selected.contains(name) { Image(systemName: "checkmark").foregroundStyle(.tint) }
                        }
                    }
                }
            } footer: {
                Text("Weekly tips tell you how these are going compared with last month.")
            }
        }
        .navigationTitle("Keep an Eye On")
        .navigationBarTitleDisplayMode(.inline)
    }
}
