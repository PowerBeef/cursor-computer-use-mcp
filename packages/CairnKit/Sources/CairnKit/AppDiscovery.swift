import AppKit
import CoreServices
import Foundation

public struct RunningAppDescriptor {
    public let name: String
    public let bundleIdentifier: String?
    public let pid: pid_t
    public let runningApplication: NSRunningApplication
}

struct ListedAppDescriptor {
    let name: String
    let bundleIdentifier: String
    let isRunning: Bool
    let isFrontmost: Bool
    let lastUsed: Date?
    let uses: Int?

    var renderedLine: String {
        var markers: [String] = []
        if isFrontmost {
            markers.append("frontmost")
        }
        if isRunning {
            markers.append("running")
        }
        if let lastUsed {
            markers.append("last-used=\(AppDiscovery.usageDateFormatter.string(from: lastUsed))")
        }
        if let uses {
            markers.append("uses=\(uses)")
        }

        return "\(name) — \(bundleIdentifier) [\(markers.joined(separator: ", "))]"
    }
}

private struct SpotlightAppRecord {
    let name: String
    let bundleIdentifier: String
    let lastUsed: Date?
    let uses: Int?
}

private struct ResolvedAppInfo {
    let bundleIdentifier: String
    let name: String
}

enum AppDiscovery {
    private static let listAppsQuery = #"kMDItemContentType == "com.apple.application-bundle" && kMDItemFSName == "*.app""#
    private static let lastUsedDateRankingAttribute = "kMDItemLastUsedDate_Ranking"
    private static let useCountAttribute = "kMDItemUseCount"
    private static let maxRecentNonRunningApps = 10
    private static let fixtureListBundleIdentifier = "com.powerbeef.cairn.fixture"
    private static let systemSettingsBundleIdentifiers = [
        "com.apple.systempreferences",
        "com.apple.settings",
    ]
    private static let appQueryAliases: [String: String] = [
        "system settings": "com.apple.systempreferences",
        "settings": "com.apple.systempreferences",
        "réglages système": "com.apple.systempreferences",
        "reglages systeme": "com.apple.systempreferences",
    ]
    private static let standardApplicationSearchRoots: [URL] = [
        URL(fileURLWithPath: "/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Applications", isDirectory: true),
        URL(fileURLWithPath: "/System/Library/CoreServices", isDirectory: true),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications", isDirectory: true),
    ]

    static let usageDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func listCatalog() -> [ListedAppDescriptor] {
        let running = userFacingRunningApps()
        let frontmostBundleIdentifier = NSWorkspace.shared.frontmostApplication?.bundleIdentifier?.lowercased()
        let runningByBundle = running.reduce(into: [String: RunningAppDescriptor]()) { result, descriptor in
            guard let bundleIdentifier = listedBundleIdentifier(for: descriptor) else {
                return
            }

            let key = bundleIdentifier.lowercased()
            if result[key] == nil {
                result[key] = descriptor
            }
        }

        var entriesByBundle: [String: ListedAppDescriptor] = [:]

        for record in SpotlightAppIndex.recentApps(cutoffDate: recentUsageCutoff()) {
            let key = record.bundleIdentifier.lowercased()
            let runningDescriptor = runningByBundle[key]
            entriesByBundle[key] = ListedAppDescriptor(
                name: runningDescriptor?.name ?? record.name,
                bundleIdentifier: record.bundleIdentifier,
                isRunning: runningDescriptor != nil,
                isFrontmost: key == frontmostBundleIdentifier,
                lastUsed: record.lastUsed,
                uses: record.uses
            )
        }

        for descriptor in running {
            guard let bundleIdentifier = listedBundleIdentifier(for: descriptor) else {
                continue
            }

            let key = bundleIdentifier.lowercased()
            let existing = entriesByBundle[key]
            entriesByBundle[key] = ListedAppDescriptor(
                name: descriptor.name,
                bundleIdentifier: bundleIdentifier,
                isRunning: true,
                isFrontmost: key == frontmostBundleIdentifier,
                lastUsed: existing?.lastUsed,
                uses: existing?.uses
            )
        }

        let sorted = entriesByBundle.values.sorted(by: compareListedApps)
        let runningEntries = sorted.filter(\.isRunning)
        let recentEntries = sorted.filter { !$0.isRunning }.prefix(maxRecentNonRunningApps)
        return (runningEntries + recentEntries).filter { entry in
            !CairnPolicy.isBlocked(bundleIdentifier: entry.bundleIdentifier, appName: entry.name)
        }
    }

    static func runningApps() -> [RunningAppDescriptor] {
        NSWorkspace.shared.runningApplications
            .filter { !$0.isTerminated }
            .sorted { lhs, rhs in
                if lhs.isActive != rhs.isActive {
                    return lhs.isActive && !rhs.isActive
                }

                return appName(lhs).localizedCaseInsensitiveCompare(appName(rhs)) == .orderedAscending
            }
            .map { app in
                RunningAppDescriptor(
                    name: appName(app),
                    bundleIdentifier: app.bundleIdentifier,
                    pid: app.processIdentifier,
                    runningApplication: app
                )
            }
    }

    static func resolve(_ query: String) throws -> RunningAppDescriptor {
        let normalizedQuery = normalizeAppQuery(query.trimmingCharacters(in: .whitespacesAndNewlines))
        let running = runningApps()

        if CairnPolicy.isBlocked(query: normalizedQuery) {
            throw CairnPolicy.permissionDenied(reference: normalizedQuery)
        }

        if let match = resolvedRunningApp(in: running, matching: normalizedQuery) {
            try CairnPolicy.assertAccess(
                query: normalizedQuery,
                bundleIdentifier: match.bundleIdentifier,
                appName: match.name
            )
            return match
        }

        try launchIfPossible(normalizedQuery)

        for _ in 0..<20 {
            if let launched = resolvedRunningApp(in: runningApps(), matching: normalizedQuery) {
                try CairnPolicy.assertAccess(
                    query: normalizedQuery,
                    bundleIdentifier: launched.bundleIdentifier,
                    appName: launched.name
                )
                return launched
            }

            Thread.sleep(forTimeInterval: 0.25)
        }

        throw CairnError.appNotFound(normalizedQuery)
    }

    internal static func normalizeAppQueryForTesting(_ query: String) -> String {
        normalizeAppQuery(query)
    }

    private static func normalizeAppQuery(_ query: String) -> String {
        let key = query.lowercased()
        return appQueryAliases[key] ?? query
    }

    private static func resolvedRunningApp(in descriptors: [RunningAppDescriptor], matching query: String) -> RunningAppDescriptor? {
        if isBundleIdentifierQuery(query) {
            let aliases = bundleIdentifierAliases(for: query)
            return descriptors.first(where: { descriptor in
                guard let bundleIdentifier = descriptor.bundleIdentifier else {
                    return false
                }

                return aliases.contains { alias in
                    bundleIdentifier.caseInsensitiveCompare(alias) == .orderedSame
                }
            })
        }

        return descriptors.first(where: { descriptor in
            guard !CairnPolicy.isBlocked(bundleIdentifier: descriptor.bundleIdentifier, appName: descriptor.name) else {
                return false
            }

            return descriptor.name.caseInsensitiveCompare(query) == .orderedSame
                || descriptor.runningApplication.executableURL?.deletingPathExtension().lastPathComponent.caseInsensitiveCompare(query) == .orderedSame
        })
    }

    private static func userFacingRunningApps() -> [RunningAppDescriptor] {
        var seen: Set<String> = []
        var descriptors: [RunningAppDescriptor] = []

        for descriptor in runningApps() {
            guard isUserFacingListApp(descriptor.runningApplication) else {
                continue
            }

            guard let bundleIdentifier = listedBundleIdentifier(for: descriptor) else {
                continue
            }

            let key = bundleIdentifier.lowercased()
            guard seen.insert(key).inserted else {
                continue
            }

            descriptors.append(descriptor)
        }

        return descriptors
    }

    private static func listedBundleIdentifier(for descriptor: RunningAppDescriptor) -> String? {
        if let bundleIdentifier = descriptor.bundleIdentifier, !bundleIdentifier.isEmpty {
            return bundleIdentifier
        }

        guard descriptor.name == FixtureBridge.appName else {
            return nil
        }

        return fixtureListBundleIdentifier
    }

    static func compareListedApps(_ lhs: ListedAppDescriptor, _ rhs: ListedAppDescriptor) -> Bool {
        if lhs.isFrontmost != rhs.isFrontmost {
            return lhs.isFrontmost && !rhs.isFrontmost
        }

        if lhs.isRunning != rhs.isRunning {
            return lhs.isRunning && !rhs.isRunning
        }

        let lhsHasUsage = lhs.lastUsed != nil
        let rhsHasUsage = rhs.lastUsed != nil
        if lhsHasUsage != rhsHasUsage {
            return lhsHasUsage && !rhsHasUsage
        }

        let calendar = Calendar(identifier: .gregorian)
        if let lhsLast = lhs.lastUsed, let rhsLast = rhs.lastUsed {
            let lhsDay = calendar.startOfDay(for: lhsLast)
            let rhsDay = calendar.startOfDay(for: rhsLast)
            if lhsDay != rhsDay {
                return lhsDay > rhsDay
            }
        }

        if let lhsUses = lhs.uses, let rhsUses = rhs.uses, lhsUses != rhsUses {
            return lhsUses > rhsUses
        }

        return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
    }

    private static func launchIfPossible(_ query: String) throws {
        if isBundleIdentifierQuery(query) {
            guard !CairnPolicy.isBlocked(query: query) else {
                return
            }

            for bundleIdentifier in bundleIdentifierAliases(for: query) {
                if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
                    try openApplication(at: appURL)
                    return
                }
            }
            return
        }

        guard let appURL = applicationURL(named: query) else {
            return
        }

        if CairnPolicy.isBlocked(
            bundleIdentifier: Bundle(url: appURL)?.bundleIdentifier,
            appName: query
        ) {
            return
        }

        try openApplication(at: appURL)
    }

    private static func applicationURL(named query: String) -> URL? {
        let targetName = stripAppSuffix(from: query).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !targetName.isEmpty else {
            return nil
        }

        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isApplicationKey, .isDirectoryKey, .nameKey]
        var visitedPaths: Set<String> = []

        for root in standardApplicationSearchRoots where fileManager.fileExists(atPath: root.path) {
            guard let enumerator = fileManager.enumerator(
                at: root,
                includingPropertiesForKeys: resourceKeys,
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let candidateURL as URL in enumerator {
                guard candidateURL.pathExtension.caseInsensitiveCompare("app") == .orderedSame else {
                    continue
                }

                let normalizedPath = candidateURL.standardizedFileURL.path.lowercased()
                guard visitedPaths.insert(normalizedPath).inserted else {
                    continue
                }

                let candidateName = stripAppSuffix(from: candidateURL.lastPathComponent)
                if candidateName.caseInsensitiveCompare(targetName) == .orderedSame {
                    return candidateURL
                }
            }
        }

        return nil
    }

    private static func openApplication(at appURL: URL) throws {
        let configuration = NSWorkspace.OpenConfiguration()
        let semaphore = DispatchSemaphore(value: 0)
        let errorBox = LaunchErrorBox()

        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            errorBox.error = error
            semaphore.signal()
        }

        waitForSignal(semaphore)

        if let launchError = errorBox.error {
            throw launchError
        }
    }

    private static func waitForSignal(_ semaphore: DispatchSemaphore) {
        if Thread.isMainThread {
            while semaphore.wait(timeout: .now()) == .timedOut {
                RunLoop.current.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
            }
            return
        }

        semaphore.wait()
    }

    private final class LaunchErrorBox: @unchecked Sendable {
        var error: Error?
    }

    private static func recentUsageCutoff(referenceDate: Date = Date()) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        let startOfToday = calendar.startOfDay(for: referenceDate)
        return calendar.date(byAdding: .day, value: -13, to: startOfToday) ?? startOfToday
    }

    private static func isBundleIdentifierQuery(_ query: String) -> Bool {
        query.contains(".")
    }

    private static func bundleIdentifierAliases(for query: String) -> [String] {
        let normalized = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if systemSettingsBundleIdentifiers.contains(where: { $0.caseInsensitiveCompare(normalized) == .orderedSame }) {
            return systemSettingsBundleIdentifiers
        }

        return [normalized]
    }

    private static func isUserFacingListApp(_ app: NSRunningApplication) -> Bool {
        if appName(app) == FixtureBridge.appName {
            return true
        }

        return app.activationPolicy == .regular
    }

    private static func bundleDisplayName(_ bundle: Bundle?) -> String? {
        guard let bundle else {
            return nil
        }

        let displayName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        let bundleName = bundle.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String
        return displayName ?? bundleName
    }

    private static func stripAppSuffix(from value: String) -> String {
        value.hasSuffix(".app") ? String(value.dropLast(4)) : value
    }

    static func appName(_ app: NSRunningApplication) -> String {
        app.localizedName
            ?? bundleDisplayName(Bundle(url: app.bundleURL ?? URL(fileURLWithPath: "/")))
            ?? app.bundleURL?.deletingPathExtension().lastPathComponent
            ?? app.executableURL?.lastPathComponent
            ?? "pid-\(app.processIdentifier)"
    }

    private enum SpotlightAppIndex {
        static func recentApps(cutoffDate: Date) -> [SpotlightAppRecord] {
            let sortingAttributes = [
                lastUsedDateRankingAttribute as CFString,
                useCountAttribute as CFString,
            ] as CFArray

            guard let query = MDQueryCreate(
                kCFAllocatorDefault,
                listAppsQuery as CFString,
                nil,
                sortingAttributes
            ) else {
                return []
            }

            MDQuerySetSearchScope(query, standardSearchScopes() as CFArray, 0)
            MDQuerySetSortOptionFlagsForAttribute(query, lastUsedDateRankingAttribute as CFString, kMDQueryReverseSortOrderFlag.rawValue)
            MDQuerySetSortOptionFlagsForAttribute(query, useCountAttribute as CFString, kMDQueryReverseSortOrderFlag.rawValue)

            guard MDQueryExecute(query, CFOptionFlags(kMDQuerySynchronous.rawValue)) else {
                return []
            }

            var seen: Set<String> = []
            var records: [SpotlightAppRecord] = []

            for index in 0..<MDQueryGetResultCount(query) {
                guard let rawResult = MDQueryGetResultAtIndex(query, index) else {
                    continue
                }

                let item = unsafeBitCast(rawResult, to: MDItem.self)
                guard
                    let bundleIdentifier = stringAttribute(kMDItemCFBundleIdentifier, item: item),
                    !bundleIdentifier.isEmpty
                else {
                    continue
                }

                let key = bundleIdentifier.lowercased()
                guard seen.insert(key).inserted else {
                    continue
                }

                guard let path = stringAttribute(kMDItemPath, item: item) else {
                    continue
                }

                let appURL = URL(fileURLWithPath: path)
                let bundle = Bundle(url: appURL)
                if bundle?.object(forInfoDictionaryKey: "LSBackgroundOnly") as? Bool == true {
                    continue
                }
                if bundle?.object(forInfoDictionaryKey: "LSUIElement") as? Bool == true {
                    continue
                }

                let lastUsed = dateAttribute(lastUsedDateRankingAttribute as CFString, item: item)
                    ?? dateAttribute(kMDItemLastUsedDate, item: item)
                guard let lastUsed, lastUsed >= cutoffDate else {
                    continue
                }

                let uses = numberAttribute(useCountAttribute as CFString, item: item)?.intValue
                let displayName = bundleDisplayName(bundle)
                    ?? stringAttribute(kMDItemDisplayName, item: item).map(stripAppSuffix(from:))
                    ?? stripAppSuffix(from: appURL.lastPathComponent)

                records.append(
                    SpotlightAppRecord(
                        name: displayName,
                        bundleIdentifier: bundleIdentifier,
                        lastUsed: lastUsed,
                        uses: uses
                    )
                )
            }

            return records
        }

        private static func standardSearchScopes() -> [CFString] {
            var scopes: [String] = [
                "/Applications",
                "/System/Applications",
                "/System/Library/CoreServices",
            ]

            let homeApplications = NSString(string: "~/Applications").expandingTildeInPath
            if FileManager.default.fileExists(atPath: homeApplications) {
                scopes.append(homeApplications)
            }

            return scopes as [CFString]
        }

        private static func stringAttribute(_ name: CFString, item: MDItem) -> String? {
            MDItemCopyAttribute(item, name) as? String
        }

        private static func numberAttribute(_ name: CFString, item: MDItem) -> NSNumber? {
            MDItemCopyAttribute(item, name) as? NSNumber
        }

        private static func dateAttribute(_ name: CFString, item: MDItem) -> Date? {
            MDItemCopyAttribute(item, name) as? Date
        }
    }
}

enum AppSafetyPolicy {
    private static let blockedBundleIdentifiers: Set<String> = [
        "com.1password.1password",
        "com.1password.safari",
        "com.apple.Passwords",
        "com.bitwarden.desktop",
        "com.dashlane.dashlanephonefinal",
        "com.lastpass.LastPass",
        "com.nordsec.nordpass",
        "me.proton.pass.electron",
        "me.proton.pass.catalyst",
    ]

    static func isBlocked(bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier else {
            return false
        }

        return blockedBundleIdentifiers.contains(bundleIdentifier)
    }

    static func permissionDenied(bundleIdentifier: String) -> CairnError {
        CairnPolicy.permissionDenied(reference: bundleIdentifier, reason: .passwordManager)
    }
}
