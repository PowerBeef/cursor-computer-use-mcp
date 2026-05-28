import Foundation

public final class CairnToolDispatcher {
    private let service: CairnService

    public init(service: CairnService = CairnService()) {
        self.service = service
    }

    public func callTool(name: String, arguments: [String: Any]) throws -> ToolCallResult {
        let includeScreenshot = optionalBool("include_screenshot", in: arguments) ?? false

        switch name {
        case "list_apps":
            return service.listApps()
        case "get_app_state":
            let format = SnapshotOutputFormat(rawValue: optionalString("format", in: arguments) ?? "text") ?? .text
            return try service.getAppState(
                app: requireString("app", in: arguments),
                format: format,
                includeOCR: optionalBool("ocr", in: arguments),
                inlineImage: optionalBool("inline_image", in: arguments) ?? false
            )
        case "click":
            return try service.click(
                app: requireString("app", in: arguments),
                elementIndex: optionalString("element_index", in: arguments),
                x: optionalDouble("x", in: arguments),
                y: optionalDouble("y", in: arguments),
                clickCount: Int(optionalDouble("click_count", in: arguments) ?? 1),
                mouseButton: optionalString("mouse_button", in: arguments) ?? "left",
                includeScreenshot: includeScreenshot
            )
        case "perform_secondary_action":
            return try service.performSecondaryAction(
                app: requireString("app", in: arguments),
                elementIndex: requireString("element_index", in: arguments),
                action: requireString("action", in: arguments),
                includeScreenshot: includeScreenshot
            )
        case "scroll":
            return try service.scroll(
                app: requireString("app", in: arguments),
                direction: requireString("direction", in: arguments),
                elementIndex: requireString("element_index", in: arguments),
                pages: optionalDouble("pages", in: arguments) ?? 1,
                includeScreenshot: includeScreenshot
            )
        case "drag":
            return try service.drag(
                app: requireString("app", in: arguments),
                fromX: requireDouble("from_x", in: arguments),
                fromY: requireDouble("from_y", in: arguments),
                toX: requireDouble("to_x", in: arguments),
                toY: requireDouble("to_y", in: arguments),
                includeScreenshot: includeScreenshot
            )
        case "type_text":
            return try service.typeText(
                app: requireString("app", in: arguments),
                text: requireString("text", in: arguments),
                includeScreenshot: includeScreenshot
            )
        case "press_key":
            return try service.pressKey(
                app: requireString("app", in: arguments),
                key: requireString("key", in: arguments),
                includeScreenshot: includeScreenshot
            )
        case "set_value":
            return try service.setValue(
                app: requireString("app", in: arguments),
                elementIndex: requireString("element_index", in: arguments),
                value: requireString("value", in: arguments),
                includeScreenshot: includeScreenshot
            )
        default:
            throw CairnError.unsupportedTool(name)
        }
    }

    public func callToolAsResult(name: String, arguments: [String: Any]) -> ToolCallResult {
        do {
            return try callTool(name: name, arguments: arguments)
        } catch let error as CairnError {
            return ToolCallResult.text(
                error.errorDescription ?? String(describing: error),
                isError: error.toolResultIsError
            )
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            return ToolCallResult.text(message, isError: true)
        }
    }

    private func requireString(_ key: String, in arguments: [String: Any]) throws -> String {
        guard let value = arguments[key] as? String, !value.isEmpty else {
            throw CairnError.missingArgument(key)
        }

        return value
    }

    private func optionalString(_ key: String, in arguments: [String: Any]) -> String? {
        arguments[key] as? String
    }

    private func requireDouble(_ key: String, in arguments: [String: Any]) throws -> Double {
        guard let value = optionalDouble(key, in: arguments) else {
            throw CairnError.missingArgument(key)
        }

        return value
    }

    private func optionalDouble(_ key: String, in arguments: [String: Any]) -> Double? {
        if let double = arguments[key] as? Double {
            return double
        }

        if let integer = arguments[key] as? Int {
            return Double(integer)
        }

        if let number = arguments[key] as? NSNumber {
            return number.doubleValue
        }

        return nil
    }

    private func optionalBool(_ key: String, in arguments: [String: Any]) -> Bool? {
        if let value = arguments[key] as? Bool {
            return value
        }
        if let number = arguments[key] as? NSNumber {
            return number.boolValue
        }
        return nil
    }
}

public struct CairnCallSpec {
    public let tool: String
    public let arguments: [String: Any]

    public init(tool: String, arguments: [String: Any]) {
        self.tool = tool
        self.arguments = arguments
    }
}

public struct CairnCallOutput {
    public let jsonObject: Any
    public let hasToolError: Bool

    public init(jsonObject: Any, hasToolError: Bool) {
        self.jsonObject = jsonObject
        self.hasToolError = hasToolError
    }

    public func jsonText() throws -> String {
        let data = try JSONSerialization.data(
            withJSONObject: jsonObject,
            options: [.prettyPrinted, .withoutEscapingSlashes]
        )
        guard let text = String(data: data, encoding: .utf8) else {
            throw CairnError.message("Failed to encode call output as JSON.")
        }
        return text
    }
}

public typealias CairnSleepHandler = (TimeInterval) -> Void

public func runCairnCall(
    _ invocation: CairnCallInvocation,
    service: CairnService = CairnService(),
    sleepHandler: CairnSleepHandler = { Thread.sleep(forTimeInterval: $0) }
) throws -> CairnCallOutput {
    let dispatcher = CairnToolDispatcher(service: service)

    switch invocation {
    case let .single(toolName, argumentsJSON, argumentsFile):
        let arguments = try readCairnToolArguments(
            json: argumentsJSON,
            file: argumentsFile
        )
        let result = dispatcher.callToolAsResult(name: toolName, arguments: arguments)
        return CairnCallOutput(
            jsonObject: result.asDictionary,
            hasToolError: result.isError
        )

    case let .sequence(callsJSON, callsFile, interCallDelay):
        let calls = try readCairnCallSequence(json: callsJSON, file: callsFile)
        var outputs: [[String: Any]] = []
        var hasToolError = false

        for (index, call) in calls.enumerated() {
            let result = dispatcher.callToolAsResult(name: call.tool, arguments: call.arguments)
            outputs.append([
                "tool": call.tool,
                "result": result.asDictionary,
            ])

            if result.isError {
                hasToolError = true
                break
            }

            if index < calls.count - 1, interCallDelay > 0 {
                sleepHandler(interCallDelay)
            }
        }

        return CairnCallOutput(jsonObject: outputs, hasToolError: hasToolError)
    }
}

public func readCairnToolArguments(
    json: String?,
    file: String?
) throws -> [String: Any] {
    guard let source = try readCairnJSONSource(json: json, file: file) else {
        return [:]
    }

    let object = try decodeCairnJSONObject(source)
    guard let arguments = object as? [String: Any] else {
        throw CairnCLIError(message: "--args must be a JSON object", helpCommand: "call")
    }

    return arguments
}

public func readCairnCallSequence(
    json: String?,
    file: String?
) throws -> [CairnCallSpec] {
    guard let source = try readCairnJSONSource(json: json, file: file) else {
        throw CairnCLIError(message: "call sequence requires --calls or --calls-file", helpCommand: "call")
    }

    let object = try decodeCairnJSONObject(source)
    guard let array = object as? [Any] else {
        throw CairnCLIError(message: "--calls must be a JSON array", helpCommand: "call")
    }

    return try array.enumerated().map { index, item in
        guard let dictionary = item as? [String: Any] else {
            throw CairnCLIError(
                message: "call sequence item #\(index + 1) must be a JSON object",
                helpCommand: "call"
            )
        }

        guard let tool = (dictionary["tool"] ?? dictionary["name"]) as? String, !tool.isEmpty else {
            throw CairnCLIError(
                message: "call sequence item #\(index + 1) requires a non-empty tool",
                helpCommand: "call"
            )
        }

        let rawArguments = dictionary["args"] ?? dictionary["arguments"] ?? [:]
        guard let arguments = rawArguments as? [String: Any] else {
            throw CairnCLIError(
                message: "call sequence item #\(index + 1) args must be a JSON object",
                helpCommand: "call"
            )
        }

        return CairnCallSpec(tool: tool, arguments: arguments)
    }
}

private func readCairnJSONSource(json: String?, file: String?) throws -> String? {
    if json != nil, file != nil {
        throw CairnCLIError(message: "Use either inline JSON or a JSON file, not both", helpCommand: "call")
    }

    if let json {
        return json
    }

    guard let file else {
        return nil
    }

    do {
        return try String(contentsOfFile: file, encoding: .utf8)
    } catch {
        throw CairnCLIError(
            message: "Unable to read JSON file \(file): \(error.localizedDescription)",
            helpCommand: "call"
        )
    }
}

private func decodeCairnJSONObject(_ source: String) throws -> Any {
    guard let data = source.data(using: .utf8) else {
        throw CairnCLIError(message: "JSON input must be UTF-8 text", helpCommand: "call")
    }

    do {
        return try JSONSerialization.jsonObject(with: data)
    } catch {
        throw CairnCLIError(
            message: "Invalid JSON input: \(error.localizedDescription)",
            helpCommand: "call"
        )
    }
}
