import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(Money.codeKey) private var currency = Money.defaultCode

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
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Done") { dismiss() } }
        }
    }
}
