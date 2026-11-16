import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @AppStorage(Money.codeKey) private var currency = Money.defaultCode
    @Query(sort: \Account.createdAt) private var accounts: [Account]

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

    private let popular = ["MDL", "RON", "EUR", "USD", "GBP"]
    private var others: [String] {
        Locale.commonISOCurrencyCodes.filter { !popular.contains($0) }
    }

    var body: some View {
        NavigationStack {
            Form {
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
                    Button { choosingFile = true } label: {
                        Label("Restore from Backup…", systemImage: "arrow.counterclockwise")
                    }
                } footer: {
                    Text("Restoring replaces everything currently in the app with the backup's contents.")
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
            .task { prepareExports() }
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
