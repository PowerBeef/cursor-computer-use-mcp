import Foundation

private struct CursorCairnPolicyFile: Decodable {
    var denyPasswordManagers: Bool?
    var allowApps: [String]?
    var denyBundleIds: [String]?
}

enum CairnPolicy {
    private static let userPolicyPath = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent(".cursor/cairn-policy.json")
    private static let projectPolicyFileName = "cairn-policy.json"

    private struct LoadedPolicy {
        let denyPasswordManagers: Bool
        let allowApps: [String]
        let denyBundleIds: Set<String>
    }

    static func isBlocked(bundleIdentifier: String?, appName: String? = nil) -> Bool {
        let policy = loadPolicy()
        let bundle = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if policy.denyPasswordManagers, AppSafetyPolicy.isBlocked(bundleIdentifier: bundleIdentifier) {
            return true
        }

        if !bundle.isEmpty, policy.denyBundleIds.contains(bundle.lowercased()) {
            return true
        }

        if !policy.allowApps.isEmpty {
            return !isAllowedByAllowList(
                query: nil,
                bundleIdentifier: bundle.isEmpty ? nil : bundle,
                appName: name.isEmpty ? nil : name,
                allowApps: policy.allowApps
            )
        }

        return false
    }

    static func isBlocked(query: String) -> Bool {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else {
            return false
        }

        let policy = loadPolicy()

        if policy.denyPasswordManagers, AppSafetyPolicy.isBlocked(bundleIdentifier: normalized) {
            return true
        }

        if policy.denyBundleIds.contains(normalized.lowercased()) {
            return true
        }

        if !policy.allowApps.isEmpty {
            return !isAllowedByAllowList(
                query: normalized,
                bundleIdentifier: isBundleIdentifierQuery(normalized) ? normalized : nil,
                appName: isBundleIdentifierQuery(normalized) ? nil : normalized,
                allowApps: policy.allowApps
            )
        }

        return false
    }

    static func permissionDenied(reference: String, reason: PolicyDenialReason = .general) -> CairnError {
        let paths = policyPaths().map(\.path).joined(separator: " or ")
        let hint: String
        switch reason {
        case .passwordManager:
            hint = "Password managers and com.apple.Passwords are denied by default (denyPasswordManagers)."
        case .allowList:
            hint = "Only apps listed in allowApps are permitted."
        case .denyBundle:
            hint = "The bundle ID is listed in denyBundleIds."
        case .general:
            hint = "Edit policy allow/deny rules."
        }
        return .permissionDenied(
            "Cairn blocked '\(reference)' by policy (\(hint)). Configure: \(paths.isEmpty ? "~/.cursor/cairn-policy.json" : paths)."
        )
    }

    enum PolicyDenialReason {
        case general
        case passwordManager
        case allowList
        case denyBundle
    }

    static func assertAccess(query: String, bundleIdentifier: String?, appName: String) throws {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if let reason = denialReason(query: normalized) {
            throw permissionDenied(reference: bundleIdentifier ?? normalized, reason: reason)
        }

        if let reason = denialReason(bundleIdentifier: bundleIdentifier, appName: appName) {
            throw permissionDenied(reference: bundleIdentifier ?? appName, reason: reason)
        }
    }

    private static func denialReason(query: String) -> PolicyDenialReason? {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalized.isEmpty else { return nil }
        let policy = loadPolicy()
        if policy.denyPasswordManagers, AppSafetyPolicy.isBlocked(bundleIdentifier: normalized) {
            return .passwordManager
        }
        if policy.denyBundleIds.contains(normalized.lowercased()) {
            return .denyBundle
        }
        if !policy.allowApps.isEmpty,
           !isAllowedByAllowList(
               query: normalized,
               bundleIdentifier: isBundleIdentifierQuery(normalized) ? normalized : nil,
               appName: isBundleIdentifierQuery(normalized) ? nil : normalized,
               allowApps: policy.allowApps
           )
        {
            return .allowList
        }
        return nil
    }

    private static func denialReason(bundleIdentifier: String?, appName: String?) -> PolicyDenialReason? {
        let policy = loadPolicy()
        let bundle = bundleIdentifier?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = appName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if policy.denyPasswordManagers, AppSafetyPolicy.isBlocked(bundleIdentifier: bundleIdentifier) {
            return .passwordManager
        }
        if !bundle.isEmpty, policy.denyBundleIds.contains(bundle.lowercased()) {
            return .denyBundle
        }
        if !policy.allowApps.isEmpty,
           !isAllowedByAllowList(
               query: nil,
               bundleIdentifier: bundle.isEmpty ? nil : bundle,
               appName: name.isEmpty ? nil : name,
               allowApps: policy.allowApps
           )
        {
            return .allowList
        }
        return nil
    }

    private static func loadPolicy() -> LoadedPolicy {
        var merged = CursorCairnPolicyFile(
            denyPasswordManagers: true,
            allowApps: [],
            denyBundleIds: []
        )

        for path in policyPaths() {
            guard let data = try? Data(contentsOf: path),
                  let file = try? JSONDecoder().decode(CursorCairnPolicyFile.self, from: data)
            else {
                continue
            }

            if let denyPasswordManagers = file.denyPasswordManagers {
                merged.denyPasswordManagers = denyPasswordManagers
            }
            if let allowApps = file.allowApps {
                merged.allowApps = allowApps
            }
            if let denyBundleIds = file.denyBundleIds {
                merged.denyBundleIds = (merged.denyBundleIds ?? []) + denyBundleIds
            }
        }

        return LoadedPolicy(
            denyPasswordManagers: merged.denyPasswordManagers ?? true,
            allowApps: merged.allowApps ?? [],
            denyBundleIds: Set((merged.denyBundleIds ?? []).map { $0.lowercased() })
        )
    }

    private static func projectRootURL() -> URL? {
        guard let raw = ProcessInfo.processInfo.environment["CAIRN_PROJECT_ROOT"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !raw.isEmpty
        else {
            return nil
        }

        return URL(fileURLWithPath: raw, isDirectory: true)
    }

    private static func policyPaths() -> [URL] {
        var paths: [URL] = [userPolicyPath]
        if let projectRoot = projectRootURL() {
            paths.append(projectRoot.appendingPathComponent(".cursor/\(projectPolicyFileName)"))
        } else {
            let cwd = URL(fileURLWithPath: FileManager.default.currentDirectoryPath, isDirectory: true)
            paths.append(cwd.appendingPathComponent(".cursor/\(projectPolicyFileName)"))
        }
        return paths
    }

    private static func isAllowedByAllowList(
        query: String?,
        bundleIdentifier: String?,
        appName: String?,
        allowApps: [String]
    ) -> Bool {
        let candidates = [query, bundleIdentifier, appName]
            .compactMap { $0?.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !candidates.isEmpty else {
            return false
        }

        let allowed = allowApps
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }

        return candidates.contains { candidate in
            let normalized = candidate.lowercased()
            return allowed.contains { allowedEntry in
                normalized == allowedEntry
                    || normalized.hasSuffix(".\(allowedEntry)")
                    || allowedEntry.hasSuffix(".\(normalized)")
            }
        }
    }

    private static func isBundleIdentifierQuery(_ query: String) -> Bool {
        query.contains(".") && !query.contains(" ")
    }
}

enum MCPTextTruncation {
    private static let defaultMaxChars = 24_000
    private static let suffix = "\n\n[truncated]"

    static func truncate(_ text: String, environment: [String: String] = ProcessInfo.processInfo.environment) -> String {
        let maxChars = maxChars(from: environment)
        guard text.count > maxChars else {
            return text
        }

        let keepCount = max(0, maxChars - suffix.count)
        let endIndex = text.index(text.startIndex, offsetBy: keepCount, limitedBy: text.endIndex) ?? text.endIndex
        return String(text[..<endIndex]) + suffix
    }

    static func truncate(_ result: ToolCallResult, environment: [String: String] = ProcessInfo.processInfo.environment) -> ToolCallResult {
        let maxChars = maxChars(from: environment)
        guard maxChars > 0 else {
            return result
        }

        let content = result.content.map { item -> ToolResultContentItem in
            guard item.dictionary["type"] as? String == "text",
                  let text = item.dictionary["text"] as? String,
                  text.count > maxChars
            else {
                return item
            }

            return .text(truncate(text, environment: environment))
        }

        return ToolCallResult(content: content, isError: result.isError)
    }

    private static func maxChars(from environment: [String: String]) -> Int {
        guard let raw = environment["CAIRN_MAX_TEXT_CHARS"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            let value = Int(raw),
            value > 0
        else {
            return defaultMaxChars
        }

        return value
    }
}
