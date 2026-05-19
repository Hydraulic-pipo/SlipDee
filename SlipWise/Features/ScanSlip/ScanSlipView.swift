import PhotosUI
import SwiftUI

struct ScanSlipView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ScanSlipViewModel()
    @State private var showingManualFallback = false

    let onSaveComplete: (() -> Void)?

    init(onSaveComplete: (() -> Void)? = nil) {
        self.onSaveComplete = onSaveComplete
    }

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Choose a bank slip image to record your transaction.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    uploadCard
                    importActions

                    if viewModel.isProcessing {
                        statusCard(
                            title: "Reading your slip",
                            message: "SlipDee is extracting transaction details for your review."
                        )
                    }

                    if let errorMessage = viewModel.errorMessage {
                        statusCard(
                            title: "We could not read this slip automatically.",
                            message: "\(errorMessage) You can still enter the details manually.",
                            accent: AppColors.expense
                        )
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
        .navigationDestination(item: $viewModel.extractedResult) { result in
            ConfirmTransactionView(
                initialResult: result,
                previewImage: viewModel.selectedImage,
                onSaveComplete: {
                    onSaveComplete?()
                    dismiss()
                }
            )
        }
        .sheet(isPresented: $showingManualFallback) {
            ManualTransactionFormView()
        }
        .task(id: viewModel.selectedItem) {
            guard viewModel.selectedItem != nil else { return }
            await viewModel.processSelectedItem()
        }
        .onAppear {
            viewModel.reset()
        }
    }

    private var uploadCard: some View {
        AppCard {
            ZStack {
                RoundedRectangle(cornerRadius: AppCornerRadius.medium, style: .continuous)
                    .fill(AppColors.elevatedCardBackground)
                    .frame(height: 320)

                if let selectedImage = viewModel.selectedImage {
                    Image(uiImage: selectedImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity, maxHeight: 292)
                        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        .padding(14)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text.image")
                            .font(.system(size: 46, weight: .regular))
                            .foregroundStyle(AppColors.primaryTeal)

                        Text("Select a bank slip image")
                            .font(.headline)
                            .foregroundStyle(AppColors.primaryText)

                        Text("SlipDee will read your slip and help fill transaction details.")
                            .font(.subheadline)
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 24)
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

            if viewModel.errorMessage != nil {
                Button("Enter Manually Instead") {
                    showingManualFallback = true
                }
                .buttonStyle(SecondaryFintechButtonStyle())
            }

            if viewModel.selectedImage != nil && !viewModel.isProcessing {
                Button("Choose Another Image") {
                    viewModel.reset()
                }
                .buttonStyle(SecondaryFintechButtonStyle())
            }
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
                    Text("SlipDee only scans the photo you choose.")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppColors.primaryText)
                    Text("Processing stays on this device.")
                        .font(.caption)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private func statusCard(title: String, message: String, accent: Color = AppColors.primaryTeal) -> some View {
        AppCard {
            HStack(spacing: 14) {
                if viewModel.isProcessing {
                    ProgressView()
                        .tint(accent)
                } else {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(accent)
                }

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
