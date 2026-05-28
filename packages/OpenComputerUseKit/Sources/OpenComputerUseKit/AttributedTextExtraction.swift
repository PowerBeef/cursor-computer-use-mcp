import ApplicationServices
import Foundation

/// Best-effort rich text extraction for web areas and text fields (TextKit 2 / Electron).
enum AttributedTextExtraction {
    private static let maxExcerptLength = 4_000

    static func excerpt(from element: AXUIElement) -> String? {
        guard let role = copyRole(of: element) else {
            return nil
        }

        let eligibleRoles: Set<String> = [
            "AXWebArea",
            "AXTextArea",
            "AXTextField",
            kAXTextAreaRole as String,
            kAXTextFieldRole as String,
        ]
        guard eligibleRoles.contains(role) else {
            return nil
        }

        if let markerRange = copyTextMarkerRange(for: element),
           let attributed = copyAttributedString(for: element, markerRange: markerRange)
        {
            return sanitizeExcerpt(attributed)
        }

        return nil
    }

    private static func copyTextMarkerRange(for element: AXUIElement) -> CFTypeRef? {
        var rangeValue: CFTypeRef?
        let error = AXUIElementCopyAttributeValue(
            element,
            "AXSelectedTextMarkerRange" as CFString,
            &rangeValue
        )
        if error == .success, rangeValue != nil {
            return rangeValue
        }

        var startMarker: CFTypeRef?
        var endMarker: CFTypeRef?
        guard
            AXUIElementCopyAttributeValue(element, "AXStartTextMarker" as CFString, &startMarker) == .success,
            AXUIElementCopyAttributeValue(element, "AXEndTextMarker" as CFString, &endMarker) == .success,
            let startMarker,
            let endMarker
        else {
            return nil
        }

        let range = [
            "AXStartTextMarker": startMarker,
            "AXEndTextMarker": endMarker,
        ] as CFDictionary

        return range
    }

    private static func copyAttributedString(for element: AXUIElement, markerRange: CFTypeRef) -> String? {
        var attributedValue: CFTypeRef?
        let error = AXUIElementCopyParameterizedAttributeValue(
            element,
            "AXAttributedStringForTextMarkerRange" as CFString,
            markerRange,
            &attributedValue
        )
        guard error == .success, let attributedValue else {
            return nil
        }

        if let attributed = attributedValue as? NSAttributedString {
            return attributed.string
        }

        if let string = attributedValue as? String {
            return string
        }

        return nil
    }

    private static func copyRole(of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &value) == .success else {
            return nil
        }
        return value as? String
    }

    private static func sanitizeExcerpt(_ raw: String) -> String? {
        let collapsed = raw
            .replacingOccurrences(of: "\u{FFFC}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !collapsed.isEmpty else {
            return nil
        }

        if collapsed.count <= maxExcerptLength {
            return collapsed
        }

        let end = collapsed.index(collapsed.startIndex, offsetBy: maxExcerptLength)
        return String(collapsed[..<end]) + "…"
    }
}
