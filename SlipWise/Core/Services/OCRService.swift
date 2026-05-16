import UIKit
import Vision

enum OCRServiceError: LocalizedError {
    case invalidImage
    case recognitionFailed(Error)
    case noTextFound

    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "The selected image could not be prepared for OCR."
        case let .recognitionFailed(error):
            return "Text recognition failed: \(error.localizedDescription)"
        case .noTextFound:
            return "No readable text was found on the slip image."
        }
    }
}

struct OCRService {
    func recognizeText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            // Vision can read mixed Thai and English text from common mobile banking slips.
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRServiceError.recognitionFailed(error))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let lines = observations
                    .compactMap { $0.topCandidates(1).first?.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                guard !lines.isEmpty else {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                    return
                }

                continuation.resume(returning: lines)
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["th-TH", "en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRServiceError.recognitionFailed(error))
            }
        }
    }
}
