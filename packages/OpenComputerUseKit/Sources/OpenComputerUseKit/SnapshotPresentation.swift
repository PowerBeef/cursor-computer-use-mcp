import AppKit
import CoreGraphics
import CryptoKit
import Foundation

public enum SnapshotOutputFormat: String, Sendable {
    case text
    case yaml
}

public struct ScreenshotPresentationMetadata: Sendable {
    public let pixelWidth: Int
    public let pixelHeight: Int
    public let captureScale: CGFloat

    public var headerLine: String {
        "Screenshot: \(pixelWidth)x\(pixelHeight) px (scale \(String(format: "%.2f", captureScale)))"
    }
}

enum SetOfMarkRenderer {
    static func annotate(pngData: Data, records: [Int: ElementRecord]) -> Data? {
        guard let source = NSImage(data: pngData) else {
            return nil
        }

        let size = source.size
        guard size.width > 0, size.height > 0 else {
            return nil
        }

        let image = NSImage(size: size)
        image.lockFocus()

        source.draw(in: NSRect(origin: .zero, size: size))

        let indexed = records.values
            .filter { $0.localFrame != nil }
            .sorted { $0.index < $1.index }

        for record in indexed {
            guard let frame = record.localFrame, frame.width > 1, frame.height > 1 else {
                continue
            }

            let rect = NSRect(
                x: frame.origin.x,
                y: size.height - frame.origin.y - frame.height,
                width: frame.width,
                height: frame.height
            )

            let color = markColor(for: record.index)
            color.setStroke()
            let path = NSBezierPath(rect: rect)
            path.lineWidth = 2
            path.stroke()

            let label = "\(record.index)" as NSString
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.boldSystemFont(ofSize: 11),
                .foregroundColor: NSColor.white,
                .backgroundColor: color,
            ]
            let labelSize = label.size(withAttributes: attributes)
            let labelOrigin = NSPoint(
                x: rect.minX,
                y: min(rect.maxY - labelSize.height, size.height - labelSize.height)
            )
            label.draw(at: labelOrigin, withAttributes: attributes)
        }

        image.unlockFocus()

        guard let tiff = image.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:])
        else {
            return nil
        }

        return png
    }

    private static func markColor(for index: Int) -> NSColor {
        let palette: [NSColor] = [
            .systemRed, .systemBlue, .systemGreen, .systemOrange,
            .systemPurple, .systemTeal, .systemPink, .systemIndigo,
        ]
        return palette[index % palette.count]
    }
}

enum SnapshotStableElementID {
    static func make(path: [String], identifier: String?) -> String {
        let material = (path + [identifier ?? ""]).joined(separator: "|")
        let digest = SHA256.hash(data: Data(material.utf8))
        let hex = digest.prefix(6).map { String(format: "%02x", $0) }.joined()
        return "id:\(hex)"
    }
}

enum SnapshotTreeYAML {
    static func render(records: [Int: ElementRecord], lines: [String]) -> String {
        var output = "elements:\n"
        let sortedIndices = records.keys.sorted()
        for index in sortedIndices {
            guard let record = records[index] else {
                continue
            }
            let line = lines.first(where: { $0.trimmingCharacters(in: .whitespaces).hasPrefix("\(index) ") || $0.contains("\t\(index) ") })
                ?? lines.first(where: { $0.contains(" \(index) ") })
            let name = extractTitle(from: line) ?? record.identifier ?? "element"
            output += "  - index: \(index)\n"
            output += "    stable_id: \(record.stableID)\n"
            output += "    name: \(yamlQuote(name))\n"
            if let frame = record.localFrame {
                output += "    frame: { x: \(Int(frame.origin.x)), y: \(Int(frame.origin.y)), w: \(Int(frame.width)), h: \(Int(frame.height)) }\n"
            }
            if !record.prettyActions.isEmpty {
                output += "    actions: [\(record.prettyActions.map(yamlQuote).joined(separator: ", "))]\n"
            }
        }
        return output
    }

    private static func extractTitle(from line: String?) -> String? {
        guard let line else {
            return nil
        }
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let space = trimmed.firstIndex(of: " ") else {
            return nil
        }
        return String(trimmed[trimmed.index(after: space)...]).prefix(120).description
    }

    private static func yamlQuote(_ value: String) -> String {
        let escaped = value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        return "\"\(escaped)\""
    }
}

func screenshotMetadata(for pngData: Data?) -> ScreenshotPresentationMetadata? {
    guard let pngData,
          let image = NSImage(data: pngData)
    else {
        return nil
    }

    let rep = NSBitmapImageRep(data: pngData)
    let width = rep?.pixelsWide ?? Int(image.size.width.rounded())
    let height = rep?.pixelsHigh ?? Int(image.size.height.rounded())
    let captureScale: CGFloat = {
        guard let rep, rep.size.width > 0, rep.pixelsWide > 0 else {
            return 1
        }
        return CGFloat(rep.pixelsWide) / rep.size.width
    }()

    return ScreenshotPresentationMetadata(
        pixelWidth: max(width, 1),
        pixelHeight: max(height, 1),
        captureScale: captureScale
    )
}
