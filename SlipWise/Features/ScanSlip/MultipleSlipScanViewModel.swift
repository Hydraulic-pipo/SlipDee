import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class MultipleSlipScanViewModel: ObservableObject {
    @Published var selectedItems: [PhotosPickerItem] = []
    @Published var isScanning = false
    @Published var scanProgressText = ""
    @Published var results: [ScannedSlipResult] = []
    @Published var errorMessage: String?

    private let ocrService = OCRService()
    private let candidateDetectionService = SlipCandidateDetectionService()
    private let basicSlipParserService = BasicSlipParserService()
    private let duplicateDetectionService = DuplicateSlipDetectionService()

    var unrecordedSlips: [ScannedSlipResult] {
        results.filter { $0.status == .new }
    }

    var possibleDuplicates: [ScannedSlipResult] {
        results.filter { $0.status == .duplicate }
    }

    var notRecognizedResults: [ScannedSlipResult] {
        results.filter { $0.status == .notRecognized || $0.status == .failed }
    }

    var hasResults: Bool {
        !results.isEmpty
    }

    func scanSelectedItems(existingTransactions: [TransactionItem]) async {
        guard !selectedItems.isEmpty else {
            results = []
            errorMessage = nil
            scanProgressText = ""
            return
        }

        isScanning = true
        errorMessage = nil
        results = []

        let totalCount = selectedItems.count

        for (index, item) in selectedItems.enumerated() {
            scanProgressText = "\(index + 1) of \(totalCount) images scanned"

            let generatedImageName = "selected_slip_\(UUID().uuidString.prefix(8)).jpg"

            do {
                guard let data = try await item.loadTransferable(type: Data.self),
                      let image = UIImage(data: data) else {
                    results.append(
                        failedResult(
                            imageData: nil,
                            message: "The selected image could not be loaded.",
                            sourceImageName: generatedImageName
                        )
                    )
                    continue
                }

                let ocrResult = try await ocrService.recognizeTextResult(from: image)
                let candidateResult = candidateDetectionService.detectSlipCandidate(from: ocrResult.rawText)

                var parsedSlip = basicSlipParserService.parse(
                    rawText: ocrResult.rawText,
                    recognizedLines: ocrResult.recognizedLines,
                    confidence: max(ocrResult.confidence, candidateResult.confidence),
                    sourceImageName: generatedImageName,
                    originalFileName: item.itemIdentifier
                )

                let duplicateCheck = duplicateDetectionService.checkDuplicate(
                    parsedSlip: parsedSlip,
                    existingTransactions: existingTransactions
                )

                let status: ScannedSlipStatus
                let duplicateReason: String?

                if !candidateResult.isLikelySlip {
                    status = .notRecognized
                    duplicateReason = candidateResult.reason
                } else if duplicateCheck.isDuplicate {
                    status = .duplicate
                    duplicateReason = duplicateCheck.reason
                } else {
                    status = .new
                    duplicateReason = nil
                }

                parsedSlip.reviewStatus = status
                parsedSlip.duplicateReason = duplicateReason
                parsedSlip.bankName = parsedSlip.bankName ?? candidateResult.detectedBankName
                parsedSlip.status = status == .notRecognized ? .failed : .needsReview

                results.append(
                    ScannedSlipResult(
                        imageData: data,
                        rawOCRText: ocrResult.rawText,
                        isLikelySlip: candidateResult.isLikelySlip,
                        status: status,
                        duplicateReason: duplicateReason,
                        parsedSlip: parsedSlip
                    )
                )
            } catch {
                results.append(
                    failedResult(
                        imageData: try? await item.loadTransferable(type: Data.self),
                        message: error.localizedDescription,
                        sourceImageName: generatedImageName
                    )
                )
            }
        }

        scanProgressText = totalCount == 0 ? "" : "\(totalCount) of \(totalCount) images scanned"
        isScanning = false
    }

    func clearResults() {
        selectedItems = []
        results = []
        errorMessage = nil
        scanProgressText = ""
        isScanning = false
    }

    func rescan(existingTransactions: [TransactionItem]) async {
        await scanSelectedItems(existingTransactions: existingTransactions)
    }

    private func failedResult(imageData: Data?, message: String, sourceImageName: String) -> ScannedSlipResult {
        let parsedSlip = ParsedSlip(
            rawOCRText: "",
            reviewStatus: .failed,
            duplicateReason: message,
            originalFileName: nil,
            sourceImageName: sourceImageName,
            status: .failed
        )

        return ScannedSlipResult(
            imageData: imageData,
            rawOCRText: "",
            isLikelySlip: false,
            status: .failed,
            duplicateReason: message,
            parsedSlip: parsedSlip
        )
    }
}
