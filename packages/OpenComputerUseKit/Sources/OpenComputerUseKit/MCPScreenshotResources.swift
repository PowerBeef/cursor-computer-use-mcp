import Foundation

public final class MCPScreenshotResourceStore: @unchecked Sendable {
    public static let shared = MCPScreenshotResourceStore()

    private let lock = NSLock()
    private var latestURI: String?
    private var latestPNG: Data?

    private init() {}

    public func store(pngData: Data) -> String {
        let uri = "computer-use://screenshot/latest"
        lock.lock()
        latestURI = uri
        latestPNG = pngData
        lock.unlock()
        return uri
    }

    public func pngData(for uri: String) -> Data? {
        lock.lock()
        defer { lock.unlock() }
        guard uri == latestURI else {
            return nil
        }
        return latestPNG
    }

    public func list() -> [[String: Any]] {
        lock.lock()
        defer { lock.unlock() }
        guard let latestURI else {
            return []
        }
        return [
            [
                "uri": latestURI,
                "name": "Latest app screenshot",
                "mimeType": "image/png",
            ],
        ]
    }

    public func clear() {
        lock.lock()
        latestURI = nil
        latestPNG = nil
        lock.unlock()
    }
}
