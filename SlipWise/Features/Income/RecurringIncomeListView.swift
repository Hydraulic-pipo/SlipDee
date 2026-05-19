import SwiftData
import SwiftUI

struct RecurringIncomeListView: View {
    @Environment(\.modelContext) private var modelContext

    @Query(sort: \RecurringIncome.createdAt, order: .forward)
    private var recurringIncomes: [RecurringIncome]

    @Query(sort: \TransactionCategory.sortOrder)
    private var categories: [TransactionCategory]

    @State private var showingAddSheet = false
    @State private var editingRecurringIncome: RecurringIncome?
    @State private var recurringIncomeToDelete: RecurringIncome?
    @State private var showDeleteConfirmation = false

    var body: some View {
        AppScreen {
            Group {
                if recurringIncomes.isEmpty {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: AppSpacing.section) {
                            Text("Recurring Income")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundStyle(AppColors.primaryText)

                            EmptyStateCard(
                                icon: "calendar.badge.plus",
                                title: "No recurring income yet",
                                message: "Add your salary or regular income to make monthly tracking easier."
                            )
                        }
                        .padding(.horizontal, AppSpacing.page)
                        .padding(.top, 18)
                    }
                } else {
                    List {
                        ForEach(recurringIncomes) { recurringIncome in
                            Button {
                                editingRecurringIncome = recurringIncome
                            } label: {
                                recurringIncomeRow(recurringIncome)
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                            .listRowBackground(Color.clear)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    recurringIncomeToDelete = recurringIncome
                                    showDeleteConfirmation = true
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(AppColors.background)
                }
            }
        }
        .navigationTitle("Recurring Income")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.primaryTeal)
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            NavigationStack {
                RecurringIncomeFormView()
            }
        }
        .sheet(item: $editingRecurringIncome) { recurringIncome in
            NavigationStack {
                RecurringIncomeFormView(recurringIncome: recurringIncome)
            }
        }
        .alert("Delete Recurring Income?", isPresented: $showDeleteConfirmation, presenting: recurringIncomeToDelete) { recurringIncome in
            Button("Cancel", role: .cancel) {
                recurringIncomeToDelete = nil
            }
            Button("Delete", role: .destructive) {
                deleteRecurringIncome(recurringIncome)
            }
        } message: { recurringIncome in
            Text("This will remove \(recurringIncome.name) from your expected income list.")
        }
    }

    private func recurringIncomeRow(_ recurringIncome: RecurringIncome) -> some View {
        AppCard {
            HStack(spacing: 14) {
                Image(systemName: "banknote")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppColors.darkTeal)
                    .frame(width: 38, height: 38)
                    .background(AppColors.softMint)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(recurringIncome.name)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(AmountDisplayFormatter.display(amount: recurringIncome.amount, isHidden: false))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryTeal)

                    Text(detailLine(for: recurringIncome))
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Text(recurringIncome.isActive ? "Active" : "Inactive")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(recurringIncome.isActive ? AppColors.income : AppColors.mutedText)

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppColors.mutedText)
                }
            }
        }
    }

    private func detailLine(for recurringIncome: RecurringIncome) -> String {
        let categoryName = recurringIncome.categoryID.flatMap { categoryID in
            categories.first(where: { $0.id == categoryID })?.name
        } ?? "No category"

        return "Pay day \(recurringIncome.payDay) • \(categoryName)"
    }

    private func deleteRecurringIncome(_ recurringIncome: RecurringIncome) {
        modelContext.delete(recurringIncome)

        do {
            try modelContext.save()
        } catch {
            recurringIncomeToDelete = nil
        }

        recurringIncomeToDelete = nil
    }
}
