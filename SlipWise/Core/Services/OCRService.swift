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

struct OCRResult {
    let rawText: String
    let confidence: Double
    let recognizedLines: [String]
}

final class OCRService {
    func recognizeText(from image: UIImage) async throws -> [String] {
        try await recognizeTextResult(from: image).recognizedLines
    }

    func recognizeTextResult(from image: UIImage) async throws -> OCRResult {
        guard let cgImage = image.cgImage else {
            throw OCRServiceError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: OCRServiceError.recognitionFailed(error))
                    return
                }

                let observations = request.results as? [VNRecognizedTextObservation] ?? []
                let candidates = observations.compactMap { $0.topCandidates(1).first }
                let lines = candidates
                    .map { $0.string.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }

                guard !lines.isEmpty else {
                    continuation.resume(throwing: OCRServiceError.noTextFound)
                    return
                }

                let averageConfidence = candidates.isEmpty
                    ? 0
                    : candidates.map(\.confidence).reduce(0, +) / Float(candidates.count)

                continuation.resume(
                    returning: OCRResult(
                        rawText: lines.joined(separator: "\n"),
                        confidence: Double(averageConfidence),
                        recognizedLines: lines
                    )
                )
            }

            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["th-TH", "en-US"]

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: cgImageOrientation(for: image.imageOrientation),
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRServiceError.recognitionFailed(error))
            }
        }
    }

    private func cgImageOrientation(for orientation: UIImage.Orientation) -> CGImagePropertyOrientation {
        switch orientation {
        case .up:
            return .up
        case .down:
            return .down
        case .left:
            return .left
        case .right:
            return .right
        case .upMirrored:
            return .upMirrored
        case .downMirrored:
            return .downMirrored
        case .leftMirrored:
            return .leftMirrored
        case .rightMirrored:
            return .rightMirrored
        @unknown default:
            return .up
        }
    }
}
