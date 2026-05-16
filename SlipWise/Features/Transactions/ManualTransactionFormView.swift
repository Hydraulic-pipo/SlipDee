import SwiftData
import SwiftUI

struct ManualTransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TransactionCategory.sortOrder)
    private var categories: [TransactionCategory]

    @StateObject private var viewModel: TransactionViewModel
    @State private var showingSuccessAlert = false
    @State private var shouldDismissAfterAlert = false

    init(mode: TransactionFormMode = .add) {
        _viewModel = StateObject(wrappedValue: TransactionViewModel(mode: mode))
    }

    var body: some View {
        NavigationStack {
            AppScreen {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.section) {
                        Text(viewModel.mode.title)
                            .font(.system(size: 30, weight: .bold, design: .rounded))
                            .foregroundStyle(AppColors.primaryText)

                        amountCard
                        typeControl
                        formCard

                        if let validationMessage = viewModel.validationMessage {
                            AppCard {
                                Text(validationMessage)
                                    .font(.subheadline)
                                    .foregroundStyle(AppColors.expense)
                            }
                        }

                        Button(viewModel.mode.saveTitle) {
                            if viewModel.save(using: modelContext) {
                                shouldDismissAfterAlert = viewModel.mode.isEditing
                                showingSuccessAlert = true
                            }
                        }
                        .buttonStyle(PrimaryFintechButtonStyle())
                        .disabled(!viewModel.canSave)
                        .opacity(viewModel.canSave ? 1 : 0.55)
                    }
                    .padding(.horizontal, AppSpacing.page)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundStyle(AppColors.primaryText)
                }
            }
            .onAppear {
                viewModel.loadCategories(from: categories)
            }
            .onChange(of: categories) { _, newValue in
                viewModel.loadCategories(from: newValue)
            }
            .onChange(of: viewModel.transactionType) { _, _ in
                viewModel.loadCategories(from: categories)
            }
            .alert("Saved", isPresented: $showingSuccessAlert) {
                Button("Done") {
                    if shouldDismissAfterAlert {
                        dismiss()
                    }
                }
                if case .add = viewModel.mode {
                    Button("Add Another", role: .cancel) {}
                }
            } message: {
                Text(viewModel.successMessage ?? "Transaction saved successfully.")
            }
        }
    }

    private var amountCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Amount")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppColors.secondaryText)

                HStack(alignment: .firstTextBaseline, spacing: 10) {
                    Text("฿")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    TextField("0.00", text: $viewModel.amountText)
                        .keyboardType(.decimalPad)
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)
                }

                Text("THB by default")
                    .font(.caption)
                    .foregroundStyle(AppColors.mutedText)
            }
        }
    }

    private var typeControl: some View {
        Picker("Type", selection: $viewModel.transactionType) {
            ForEach(TransactionType.allCases) { type in
                Text(type.title).tag(type)
            }
        }
        .pickerStyle(.segmented)
    }

    private var formCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 14) {
                dateField

                AppPickerField(title: "Category", selection: $viewModel.selectedCategoryID) {
                    Text("No Category").tag(UUID?.none)
                    ForEach(viewModel.filteredCategories) { category in
                        Text(category.name).tag(Optional(category.id))
                    }
                }

                AppPickerField(title: "Payment Method", selection: $viewModel.paymentMethod) {
                    ForEach(PaymentMethod.allCases) { method in
                        Text(method.title).tag(method)
                    }
                }

                AppInputField(title: viewModel.counterpartyLabel, text: $viewModel.counterpartyName)
                AppInputField(title: "Note", text: $viewModel.note, axis: .vertical)
            }
        }
    }

    private var dateField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            DatePicker(
                "Transaction Date",
                selection: $viewModel.transactionDate,
                displayedComponents: [.date, .hourAndMinute]
            )
            .labelsHidden()
            .datePickerStyle(.compact)
            .tint(AppColors.primaryTeal)
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.elevatedCardBackground)
            .overlay(
                RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous)
                    .stroke(AppColors.border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppCornerRadius.small, style: .continuous))
        }
    }
}
