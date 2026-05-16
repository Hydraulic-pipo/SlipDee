import SwiftData
import SwiftUI

struct TransactionListView: View {
    @State private var showingManualTransactionForm = false
    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    AppSectionHeader("Transactions", subtitle: "All of your manual entries and imported slips.")

                    if transactions.isEmpty {
                        EmptyStateCard(
                            icon: "list.bullet.clipboard",
                            title: "No saved transactions yet",
                            message: "Add a manual transaction or confirm a scanned slip to start building your history."
                        )
                    } else {
                        ForEach(transactions) { transaction in
                            NavigationLink {
                                TransactionDetailView(transaction: transaction)
                            } label: {
                                TransactionRowView(transaction: transaction, showsDisclosure: true)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingManualTransactionForm = true
                } label: {
                    Image(systemName: "plus")
                        .foregroundStyle(AppColors.primaryText)
                }
                .accessibilityLabel("Add transaction")
            }
        }
        .sheet(isPresented: $showingManualTransactionForm) {
            ManualTransactionFormView()
        }
    }
}
