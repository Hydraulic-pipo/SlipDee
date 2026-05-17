import PhotosUI
import SwiftData
import SwiftUI

struct MultipleSlipScanView: View {
    @StateObject private var viewModel = MultipleSlipScanViewModel()
    @State private var pickerSelection: [PhotosPickerItem] = []
    @State private var selectedResult: ScannedSlipResult?

    @Query(sort: \TransactionItem.transactionDate, order: .reverse)
    private var transactions: [TransactionItem]

    var body: some View {
        AppScreen {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.section) {
                    Text("Scan Today’s Slips")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.primaryText)

                    Text("Select bank slip images you want SlipDee to check.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)

                    privacyCard

                    if viewModel.isScanning {
                        scanningCard
                    }

                    if viewModel.hasResults {
                        resultsContent
                    } else {
                        emptyState
                    }
                }
                .padding(.horizontal, AppSpacing.page)
                .padding(.top, 18)
                .padding(.bottom, 32)
            }
        }
        .navigationTitle("Scan Today’s Slips")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedResult) { result in
            NavigationStack {
                SlipScanReviewView(result: result)
            }
        }
        .task(id: selectionSignature) {
            guard !pickerSelection.isEmpty else { return }
            viewModel.selectedItems = pickerSelection
            await viewModel.scanSelectedItems(existingTransactions: transactions)
        }
    }

    private var emptyState: some View {
        AppCard {
            VStack(spacing: 18) {
                Image(systemName: "photo.on.rectangle.angled")
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundStyle(AppColors.primaryTeal)

                VStack(spacing: 8) {
                    Text("Select slip images from Photos")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text("SlipDee only scans photos you select. Processing stays on your device.")
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                choosePhotosButton
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
        }
    }

    private var scanningCard: some View {
        AppCard {
            HStack(spacing: 14) {
                ProgressView()
                    .tint(AppColors.primaryTeal)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Scanning selected slips…")
                        .font(.headline)
                        .foregroundStyle(AppColors.primaryText)

                    Text(viewModel.scanProgressText)
                        .font(.subheadline)
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
        }
    }

    private var resultsContent: some View {
        VStack(alignment: .leading, spacing: AppSpacing.section) {
            choosePhotosButton

            resultSection(title: "Unrecorded Slips", items: viewModel.unrecordedSlips)
            resultSection(title: "Possible Duplicates", items: viewModel.possibleDuplicates)
            resultSection(title: "Not Recognized", items: viewModel.notRecognizedResults)
        }
    }

    private func resultSection(title: String, items: [ScannedSlipResult]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            if !items.isEmpty {
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(AppColors.primaryText)

                ForEach(items) { result in
                    Button {
                        selectedResult = result
                    } label: {
                        SlipScanResultRowView(result: result)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var choosePhotosButton: some View {
        let buttonTitle = viewModel.hasResults ? "Choose More Photos" : "Choose Photos"

        return PhotosPicker(
            selection: $pickerSelection,
            maxSelectionCount: 20,
            matching: .images,
            photoLibrary: .shared()
        ) {
            Text(buttonTitle)
        }
        .buttonStyle(PrimaryFintechButtonStyle())
    }

    private var privacyCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("SlipDee only scans photos you select.")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppColors.primaryText)

                Text("Processing stays on your device. No bank account access is required.")
                    .font(.subheadline)
                    .foregroundStyle(AppColors.secondaryText)
            }
        }
    }

    private var selectionSignature: String {
        pickerSelection
            .compactMap(\.itemIdentifier)
            .sorted()
            .joined(separator: "|")
    }
}
