import PhotosUI
import SwiftUI
import UIKit

@MainActor
final class ScanSlipViewModel: ObservableObject {
    @Published var selectedItem: PhotosPickerItem?
    @Published var selectedImage: UIImage?
    @Published var extractedResult: ParsedSlip?
    @Published var isProcessing = false
    @Published var errorMessage: String?

    private let ocrService = OCRService()
    private let parserService = BasicSlipParserService()

    func processSelectedItem() async {
        guard let selectedItem else { return }

        do {
            isProcessing = true
            errorMessage = nil
            extractedResult = nil

            guard let data = try await selectedItem.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorMessage = "The selected image could not be loaded."
                isProcessing = false
                return
            }

            selectedImage = image

            // First turn the screenshot into lines of text, then convert those lines into a draft transaction.
            let sourceImageName = "selected_slip_\(UUID().uuidString.prefix(8)).jpg"
            let ocrResult = try await ocrService.recognizeTextResult(from: image)
            var parsedResult = parserService.parse(
                rawText: ocrResult.rawText,
                recognizedLines: ocrResult.recognizedLines,
                confidence: ocrResult.confidence,
                sourceImageName: sourceImageName,
                originalFileName: selectedItem.itemIdentifier
            )
            parsedResult.sourceImageName = sourceImageName
            extractedResult = parsedResult
        } catch {
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    func reset() {
        selectedItem = nil
        selectedImage = nil
        extractedResult = nil
        errorMessage = nil
        isProcessing = false
    }
}
