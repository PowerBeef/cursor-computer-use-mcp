import Foundation

let computerUseServerInstructions = """
Computer Use tools let you interact with macOS apps by performing UI actions.

Cursor workflow: list_apps → get_app_state (once per assistant turn) → act via element_index when available → verify with get_app_state. Prefer element_index from the latest accessibility tree over coordinate clicks.

For local web apps in the user's browser, prefer the cursor-ide-browser MCP server when it is enabled. Use Computer Use for native macOS apps and desktop UI that browser automation cannot reach.

The available tools are list_apps, get_app_state, click, perform_secondary_action, scroll, drag, type_text, press_key, and set_value.

Hosts that support MCP turn notifications should send notifications/turn-ended (or run `cairn turn-ended`) after each assistant turn so overlay state resets before the next turn.

Computer Use runs in the user's desktop session. Avoid disrupting their active work (for example clipboard overwrites) unless they asked.

After each action, verify the UI changed as expected using the action result or a fresh get_app_state.
Ask the user before destructive or externally visible actions such as sending, deleting, or purchasing.
"""

public final class StdioMCPServer {
    private let dispatcher: CairnToolDispatcher
    private let service: CairnService

    public init(service: CairnService = CairnService()) {
        self.service = service
        self.dispatcher = CairnToolDispatcher(service: service)
    }

    public func run() throws {
        while let line = readLine(strippingNewline: true) {
            guard !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                continue
            }

            if let response = handle(line: line) {
                FileHandle.standardOutput.write((response + "\n").data(using: .utf8)!)
            }
        }
    }

    public func handle(line: String) -> String? {
        do {
            guard let payload = try JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any] else {
                return try encodeJSONRPCError(id: nil, code: -32700, message: "Invalid JSON-RPC payload")
            }

            let method = payload["method"] as? String
            let id = payload["id"]
            let params = payload["params"] as? [String: Any] ?? [:]

            switch method {
            case "initialize":
                return try encodeJSONRPCResult(
                    id: id,
                    result: [
                        "protocolVersion": "2025-03-26",
                        "serverInfo": [
                            "name": "cairn",
                            "version": cairnVersion,
                        ],
                        "capabilities": [
                            "tools": [
                                "listChanged": false,
                            ],
                            "resources": [
                                "listChanged": false,
                            ],
                        ],
                        "instructions": computerUseServerInstructions,
                    ]
                )
            case "notifications/initialized":
                return nil
            case "notifications/turn-ended":
                VisualCursorSupport.performOnMain {
                    SoftwareCursorOverlay.reset()
                }
                CairnService.resetAllSessionCaches()
                SnapshotAXCache.shared.invalidateAll()
                return nil
            case "ping":
                return try encodeJSONRPCResult(id: id, result: [:])
            case "tools/list":
                return try encodeJSONRPCResult(
                    id: id,
                    result: [
                        "tools": ToolDefinitions.all.map(\.asDictionary),
                    ]
                )
            case "resources/list":
                return try encodeJSONRPCResult(
                    id: id,
                    result: [
                        "resources": MCPScreenshotResourceStore.shared.list(),
                    ]
                )
            case "resources/read":
                let uri = params["uri"] as? String ?? ""
                guard let pngData = MCPScreenshotResourceStore.shared.pngData(for: uri) else {
                    return try encodeJSONRPCError(id: id, code: -32602, message: "Unknown screenshot resource: \(uri)")
                }
                let base64 = pngData.base64EncodedString()
                return try encodeJSONRPCResult(
                    id: id,
                    result: [
                        "contents": [
                            [
                                "uri": uri,
                                "mimeType": "image/png",
                                "blob": base64,
                            ],
                        ],
                    ]
                )
            case "tools/call":
                let name = params["name"] as? String ?? ""
                let arguments = params["arguments"] as? [String: Any] ?? [:]
                let result = try dispatcher.callTool(name: name, arguments: arguments)
                return try encodeJSONRPCResult(
                    id: id,
                    result: result.asDictionary
                )
            default:
                if method == nil {
                    return nil
                }

                return try encodeJSONRPCError(id: id, code: -32601, message: "Method not found: \(method ?? "")")
            }
        } catch let error as CairnError {
            let payload = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
            let id = payload?["id"]
            let result = ToolCallResult.text(error.errorDescription ?? String(describing: error), isError: error.toolResultIsError)
            return try? encodeJSONRPCResult(id: id, result: result.asDictionary)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            let payload = try? JSONSerialization.jsonObject(with: Data(line.utf8)) as? [String: Any]
            let id = payload?["id"]
            return try? encodeJSONRPCResult(
                id: id,
                result: [
                    "content": [
                        [
                            "type": "text",
                            "text": message,
                        ],
                    ],
                    "isError": true,
                ]
            )
        }
    }

    private func encodeJSONRPCResult(id: Any?, result: [String: Any]) throws -> String {
        try encode([
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "result": result,
        ])
    }

    private func encodeJSONRPCError(id: Any?, code: Int, message: String) throws -> String {
        try encode([
            "jsonrpc": "2.0",
            "id": id ?? NSNull(),
            "error": [
                "code": code,
                "message": message,
            ],
        ])
    }

    private func encode(_ object: [String: Any]) throws -> String {
        let data = try JSONSerialization.data(withJSONObject: object, options: [.withoutEscapingSlashes])
        guard let text = String(data: data, encoding: .utf8) else {
            throw CairnError.message("Failed to encode JSON-RPC response.")
        }

        return text
    }
}
