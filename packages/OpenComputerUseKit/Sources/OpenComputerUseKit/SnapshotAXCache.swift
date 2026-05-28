import ApplicationServices
import Foundation

/// Lightweight AX tree cache keyed by app PID. Invalidated on MCP turn-ended and TTL expiry.
actor SnapshotAXCache {
    static let shared = SnapshotAXCache()

    private struct Entry {
        let snapshot: AppSnapshot
        let capturedAt: Date
    }

    private var entries: [pid_t: Entry] = [:]
    private let ttl: TimeInterval = 2.0

    func cachedSnapshot(for app: RunningAppDescriptor) -> AppSnapshot? {
        guard let entry = entries[app.pid] else {
            return nil
        }
        if Date().timeIntervalSince(entry.capturedAt) > ttl {
            entries.removeValue(forKey: app.pid)
            return nil
        }
        return entry.snapshot
    }

    func store(_ snapshot: AppSnapshot, for app: RunningAppDescriptor) {
        entries[app.pid] = Entry(snapshot: snapshot, capturedAt: Date())
    }

    func invalidateAll() {
        entries.removeAll()
    }

    func invalidate(pid: pid_t) {
        entries.removeValue(forKey: pid)
    }
}
