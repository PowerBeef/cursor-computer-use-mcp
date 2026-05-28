import ApplicationServices
import Foundation

/// Lightweight AX tree cache keyed by app PID. Invalidated on MCP turn-ended and TTL expiry.
public final class SnapshotAXCache: @unchecked Sendable {
    public static let shared = SnapshotAXCache()

    private struct Entry {
        let snapshot: AppSnapshot
        let capturedAt: Date
    }

    private let lock = NSLock()
    private var entries: [pid_t: Entry] = [:]
    private let ttl: TimeInterval = 2.0

    private init() {}

    public func cachedSnapshot(for app: RunningAppDescriptor) -> AppSnapshot? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = entries[app.pid] else {
            return nil
        }
        if Date().timeIntervalSince(entry.capturedAt) > ttl {
            entries.removeValue(forKey: app.pid)
            return nil
        }
        return entry.snapshot
    }

    public func store(_ snapshot: AppSnapshot, for app: RunningAppDescriptor) {
        lock.lock()
        entries[app.pid] = Entry(snapshot: snapshot, capturedAt: Date())
        lock.unlock()
    }

    public func invalidateAll() {
        lock.lock()
        entries.removeAll()
        lock.unlock()
    }

    public func invalidate(pid: pid_t) {
        lock.lock()
        entries.removeValue(forKey: pid)
        lock.unlock()
    }
}
