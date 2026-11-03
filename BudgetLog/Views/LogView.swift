import SwiftUI
import SwiftData

/// All entries, newest first, with search, add, edit and delete.
struct LogView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Entry.date, order: .reverse) private var entries: [Entry]

    @State private var searchText = ""
    @State private var isAdding = false
    @State private var editing: Entry?

    private var filtered: [Entry] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return entries }
        return entries.filter { $0.merchant.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Log")
                .searchable(text: $searchText, prompt: "Search merchants")
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            isAdding = true
                        } label: {
                            Label("Add Transaction", systemImage: "plus")
                        }
                    }
                }
                .sheet(isPresented: $isAdding) {
                    EntryFormView(entry: nil)
                }
                .sheet(item: $editing) { entry in
                    EntryFormView(entry: entry)
                }
        }
    }

    @ViewBuilder
    private var content: some View {
        if entries.isEmpty {
            ContentUnavailableView {
                Label("No transactions yet", systemImage: "creditcard")
            } description: {
                Text("Tap + to add one. Once auto-logging is set up, Apple Pay taps show up here on their own.")
            } actions: {
                Button("Add Transaction") { isAdding = true }
            }
        } else if filtered.isEmpty {
            ContentUnavailableView.search(text: searchText)
        } else {
            List {
                ForEach(filtered) { entry in
                    Button {
                        editing = entry
                    } label: {
                        EntryRow(entry: entry)
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        let doomed = offsets.map { filtered[$0] }
        for entry in doomed {
            context.delete(entry)
        }
        try? context.save()
    }
}

struct EntryRow: View {
    let entry: Entry

    private var categoryName: String { entry.category?.name ?? "Other" }
    private var categoryColor: Color { Color(hex: entry.category?.colorHex ?? StarterData.otherColorHex) }

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(categoryColor)
                .frame(width: 10, height: 10)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.merchant)
                    .lineLimit(1)
                Text("\(categoryName) · \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 2) {
                Text(Money.format(entry.amount))
                    .monospacedDigit()
                    .foregroundStyle(entry.isRefund ? Color.green : Color.primary)
                if entry.isRefund {
                    Text("Refund")
                        .font(.caption2)
                        .foregroundStyle(.green)
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }
}
