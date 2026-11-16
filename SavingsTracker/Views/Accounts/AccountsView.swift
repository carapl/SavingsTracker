import SwiftUI
import SwiftData

struct AccountsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Account.createdAt, animation: Motion.change) private var accounts: [Account]
    @State private var showingNew = false
    @State private var editing: Account?

    var body: some View {
        NavigationStack {
            List {
                if !accounts.isEmpty {
                    Section {
                        VStack(alignment: .leading) {
                            Text("Total balance").font(.subheadline).foregroundStyle(.secondary)
                            Text(accounts.sum(\.balance).currency).font(.title.bold()).monospacedDigit()
                                .rollingNumber(accounts.sum(\.balance))
                        }
                    }
                }
                Section {
                    ForEach(accounts) { account in
                        Button { editing = account } label: {
                            HStack(spacing: 12) {
                                Image(systemName: account.kind.symbol)
                                    .frame(width: 36, height: 36)
                                    .foregroundStyle(Theme.accent)
                                    .background(Theme.accent.opacity(0.15), in: Circle())
                                VStack(alignment: .leading) {
                                    Text(account.name)
                                    Text(account.kind.label).font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(account.balance.currency)
                                    .monospacedDigit()
                                    .foregroundStyle(account.balance < 0 ? .red : .primary)
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                    .onDelete { offsets in
                        for i in offsets { context.delete(accounts[i]) }
                    }
                } footer: {
                    if !accounts.isEmpty {
                        Text("Balances change when you link transactions to an account.")
                    }
                }
            }
            .overlay {
                if accounts.isEmpty {
                    ContentUnavailableView("No accounts yet", systemImage: "building.columns",
                                           description: Text("Add your bank accounts, savings or cash to see your total balance."))
                }
            }
            .navigationTitle("Accounts")
            .toolbar {
                Button { showingNew = true } label: { Image(systemName: "plus") }
                    .accessibilityLabel("Add account")
            }
            .sheet(isPresented: $showingNew) { AccountForm() }
            .sheet(item: $editing) { AccountForm(account: $0) }
        }
    }
}

struct AccountForm: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    private let account: Account?

    @State private var name: String
    @State private var kind: AccountKind
    @State private var balanceText: String

    init(account: Account? = nil) {
        self.account = account
        _name = State(initialValue: account?.name ?? "")
        _kind = State(initialValue: account?.kind ?? .checking)
        _balanceText = State(initialValue: account.map { Money.editText($0.balance) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Name, e.g. Main bank", text: $name)
                    Picker("Type", selection: $kind) {
                        ForEach(AccountKind.allCases) { Label($0.label, systemImage: $0.symbol).tag($0) }
                    }
                }
                Section {
                    AmountField(title: "Current balance", text: $balanceText, allowsNegative: true)
                } footer: {
                    Text("Start with a minus sign for money you owe, like a credit card balance.")
                }
            }
            .navigationTitle(account == nil ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let current = Money.parse(balanceText) ?? 0
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        if let account {
            account.name = trimmed
            account.kind = kind
            // Keep linked transactions intact; adjust the starting point so the balance matches what was typed.
            account.startingBalance = current - account.linkedNet
        } else {
            context.insert(Account(name: trimmed, kind: kind, startingBalance: current))
        }
        dismiss()
    }
}
