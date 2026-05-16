import PhotosUI
import SwiftUI

struct ScanSlipView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScanSlipViewModel()
    @State private var showingScanInfo = false

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    AppSectionHeader("Upload or scan your bank slip", subtitle: "Processed on your device for a private and simple flow.")

                    slipPreviewCard
                    importActions

                    if viewModel.isProcessing {
                        statusCard(
                            title: "Reading your slip",
                            message: "SlipDee is extracting transaction details for your review."
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        statusCard(
                            title: "We need a clearer slip",
                            message: errorMessage,
                            accent: AppColors.expense
                        )
                    }

                    if let result = viewModel.extractedResult {
                        AppCard {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Draft Preview")
                                    .font(.headline)
                                    .foregroundStyle(AppColors.primaryText)

                                ScanPreviewRow(title: "Amount", value: result.amount.map(CurrencyFormatter.bahtString(from:)) ?? "Not found")
                                ScanPreviewRow(title: "Bank", value: result.bankName ?? "Not found")
                                ScanPreviewRow(title: "Receiver", value: result.receiverName ?? "Not found")
                                ScanPreviewRow(title: "Reference", value: result.transactionReference ?? "Not found")
                            }
                        }

                        NavigationLink(value: result) {
                            Text("Review Transaction")
                        }
                        .buttonStyle(PrimaryFintechButtonStyle())
                    }

                    privacyCard
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Import Slip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .foregroundStyle(AppColors.primaryText)
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingScanInfo = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(AppColors.primaryText)
                }
            }
        }
        .navigationDestination(for: ParsedSlip.self) { result in
            ConfirmTransactionView(initialResult: result)
        }
        .task(id: viewModel.selectedItem) {
            guard viewModel.selectedItem != nil else { return }
            await viewModel.processSelectedItem()
        }
        .alert("Scan New Slip", isPresented: $showingScanInfo) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Camera scanning can be added next. For now, you can import slip screenshots from Photos.")
        }
    }

    private var slipPreviewCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text("Slip Preview")
                    .font(.headline)
                    .foregroundStyle(AppColors.primaryText)

                ZStack {
                    RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                        .fill(AppColors.background)
                        .frame(height: 280)

                    RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6, 6]))
                        .foregroundStyle(AppColors.border)
                        .frame(height: 280)

                    if let selectedImage = viewModel.selectedImage {
                        Image(uiImage: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity, maxHeight: 260)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .padding(12)
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.image")
                                .font(.system(size: 42, weight: .regular))
                                .foregroundStyle(AppColors.primaryTeal)

                            Text("Import your Thai bank slip")
                                .font(.headline)
                                .foregroundStyle(AppColors.primaryText)

                            Text("Slip preview will appear here before anything is saved.")
                                .font(.subheadline)
                                .foregroundStyle(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
        }
    }

    private var importActions: some View {
        VStack(spacing: 12) {
            PhotosPicker(
                selection: $viewModel.selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Import from Photos")
            }
            .buttonStyle(PrimaryFintechButtonStyle())

            Button("Scan New Slip") {
                showingScanInfo = true
            }
            .buttonStyle(SecondaryFintechButtonStyle())
        }
    }

    private var privacyCard: some View {
        AppCard {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(AppColors.darkTeal)
                    .frame(width: 36, height: 36)
                    .background(AppColors.softMint)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Processed on your device")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Your data stays private and secure.")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private func statusCard(title: String, message: String, accent: Color = AppColors.primaryTeal) -> some View {
        AppCard {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(accent)

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(message)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }
}

private struct ScanPreviewRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppColors.secondaryText)

            Spacer(minLength: 12)

            Text(value)
                .font(.subheadline)
                .foregroundStyle(AppColors.primaryText)
                .multilineTextAlignment(.trailing)
        }
    }
}
