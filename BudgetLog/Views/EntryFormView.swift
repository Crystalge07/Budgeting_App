import SwiftUI
import SwiftData

/// Add a new entry (`entry == nil`) or edit / delete an existing one.
struct EntryFormView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var rules: [MerchantRule]

    let entry: Entry?

    @State private var amountText: String
    @State private var isRefund: Bool
    @State private var merchant: String
    @State private var category: Category?
    /// True once the user picks a category themselves; Merchant typing then stops suggesting one.
    @State private var categoryChangedByUser = false
    @State private var date: Date
    @State private var paidWith: String
    @State private var confirmingDelete = false
    @FocusState private var amountFocused: Bool

    init(entry: Entry?) {
        self.entry = entry
        _amountText = State(initialValue: entry.map { Money.editableText($0.amount) } ?? "")
        _isRefund = State(initialValue: entry?.isRefund ?? false)
        _merchant = State(initialValue: entry?.merchant ?? "")
        _category = State(initialValue: entry?.category)
        _date = State(initialValue: entry?.date ?? .now)
        _paidWith = State(initialValue: entry?.cardName ?? "")
    }

    private var otherCategory: Category? { categories.first(where: \.isOther) }

    private var parsedAmount: Decimal? {
        guard let value = AmountInput.parse(amountText), value != 0 else { return nil }
        return abs(value)
    }

    private var trimmedMerchant: String { merchant.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSave: Bool { parsedAmount != nil && !trimmedMerchant.isEmpty }

    private var categorySelection: Binding<Category?> {
        Binding(
            get: { category },
            set: { newValue in
                category = newValue
                categoryChangedByUser = true
            }
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    amountField
                    Toggle("Refund", isOn: $isRefund)
                } footer: {
                    if isRefund {
                        Text("Refunds are saved as negative amounts and reduce your totals.")
                    }
                }

                Section {
                    merchantField
                    Picker("Category", selection: categorySelection) {
                        ForEach(categories) { option in
                            Text(option.name).tag(Optional(option))
                        }
                    }
                    DatePicker("Date", selection: $date)
                    TextField("Paid with (optional)", text: $paidWith, prompt: Text("Cash, debit, e-Transfer…"))
                }

                if entry != nil {
                    Section {
                        Button("Delete Transaction", role: .destructive) {
                            confirmingDelete = true
                        }
                    }
                }
            }
            .navigationTitle(entry == nil ? "New Transaction" : "Edit Transaction")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Delete this transaction?", isPresented: $confirmingDelete, titleVisibility: .visible) {
                Button("Delete", role: .destructive, action: deleteEntry)
            }
            .onChange(of: merchant) { _, _ in suggestCategory() }
            .onAppear {
                if category == nil { category = otherCategory }
                if entry == nil { amountFocused = true }
            }
        }
    }

    private var amountField: some View {
        TextField("Amount", text: $amountText, prompt: Text("0.00"))
            .font(.title2.monospacedDigit())
            .focused($amountFocused)
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
    }

    private var merchantField: some View {
        TextField("Merchant", text: $merchant)
            .autocorrectionDisabled()
            #if os(iOS)
            .textInputAutocapitalization(.words)
            #endif
    }

    private func suggestCategory() {
        // Only new entries get suggestions; edits keep the category they have.
        guard entry == nil, !categoryChangedByUser else { return }
        category = CategoryResolver.category(for: merchant, rules: rules) ?? otherCategory
    }

    private func save() {
        guard let value = parsedAmount else { return }
        let signedAmount = isRefund ? -value : value
        let paid = paidWith.trimmingCharacters(in: .whitespacesAndNewlines)
        let cardName = paid.isEmpty ? nil : paid

        if let entry {
            if categoryChangedByUser, entry.category?.id != category?.id {
                entry.categoryWasEdited = true
            }
            entry.amount = signedAmount
            entry.merchant = trimmedMerchant
            entry.category = category
            entry.date = date
            entry.cardName = cardName
        } else {
            let newEntry = Entry(
                amount: signedAmount,
                merchant: trimmedMerchant,
                date: date,
                source: .manual,
                cardName: cardName,
                category: category
            )
            newEntry.categoryWasEdited = categoryChangedByUser
            context.insert(newEntry)
        }
        try? context.save()
        dismiss()
    }

    private func deleteEntry() {
        if let entry {
            context.delete(entry)
            try? context.save()
        }
        dismiss()
    }
}
