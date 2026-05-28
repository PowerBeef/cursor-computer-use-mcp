import CoreGraphics
import Foundation
import ImageIO
import Vision

struct OCRTextObservation: Sendable {
    let text: String
    let localFrame: CGRect
}

enum OCRPipeline {
    static func defaultEnabled(environment: [String: String] = ProcessInfo.processInfo.environment) -> Bool {
        guard let raw = environment["CAIRN_OCR_DEFAULT"]?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        else {
            return false
        }
        return ["1", "true", "yes", "on"].contains(raw)
    }

    static func recognize(pngData: Data) -> [OCRTextObservation] {
        guard let image = cgImage(from: pngData) else {
            return []
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: image, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return []
        }

        guard let observations = request.results else {
            return []
        }

        let imageSize = CGSize(width: image.width, height: image.height)
        return observations.compactMap { observation in
            guard let candidate = observation.topCandidates(1).first else {
                return nil
            }
            let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                return nil
            }

            let box = observation.boundingBox
            let frame = CGRect(
                x: box.origin.x * imageSize.width,
                y: (1 - box.origin.y - box.height) * imageSize.height,
                width: box.width * imageSize.width,
                height: box.height * imageSize.height
            )
            return OCRTextObservation(text: text, localFrame: frame)
        }
    }

    private static func cgImage(from pngData: Data) -> CGImage? {
        guard let source = CGImageSourceCreateWithData(pngData as CFData, nil) else {
            return nil
        }
        return CGImageSourceCreateImageAtIndex(source, 0, nil)
    }
}
