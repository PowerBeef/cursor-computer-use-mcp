import Foundation

public enum CairnCLICommand: Equatable {
    case launchOnboarding
    case mcp
    case doctor(cursor: Bool)
    case listApps
    case snapshot(app: String)
    case call(CairnCallInvocation)
    case turnEnded(payload: String?)
    case help(command: String?)
    case version
}

public enum CairnCallInvocation: Equatable {
    case single(toolName: String, argumentsJSON: String?, argumentsFile: String?)
    case sequence(callsJSON: String?, callsFile: String?, interCallDelay: TimeInterval)
}

public let cairnDefaultInterCallDelay: TimeInterval = 1

public func shouldUseMacOSAppAgentProxy(
    command: CairnCLICommand,
    proxyDisabled: Bool,
    appBundleAvailable: Bool,
    runningFromLaunchServicesAppInstance: Bool
) -> Bool {
    guard !proxyDisabled, appBundleAvailable else {
        return false
    }

    switch command {
    case .launchOnboarding:
        return !runningFromLaunchServicesAppInstance
    case .mcp, .doctor, .listApps, .snapshot, .call:
        return true
    case .turnEnded, .help, .version:
        return false
    }
}

public struct CairnCLIError: LocalizedError, Equatable {
    public let message: String
    public let helpCommand: String?

    public init(message: String, helpCommand: String? = nil) {
        self.message = message
        self.helpCommand = helpCommand
    }

    public var errorDescription: String? {
        var lines = [message]
        lines.append("")
        lines.append(cairnHelpText(command: helpCommand))
        return lines.joined(separator: "\n")
    }
}

public func parseCairnCLI(arguments: [String]) throws -> CairnCLICommand {
    guard let first = arguments.first else {
        return .launchOnboarding
    }

    switch first {
    case "-h", "--help", "help":
        if arguments.count > 2 {
            throw CairnCLIError(message: "help accepts at most one command", helpCommand: nil)
        }

        return .help(command: arguments.dropFirst().first)
    case "-v", "--version", "version":
        guard arguments.count == 1 else {
            throw CairnCLIError(message: "version does not accept any arguments", helpCommand: nil)
        }

        return .version
    case "mcp":
        return try parseSimpleCommand(name: "mcp", arguments: Array(arguments.dropFirst()), result: .mcp)
    case "doctor":
        return try parseDoctor(arguments: Array(arguments.dropFirst()))
    case "list-apps":
        return try parseSimpleCommand(name: "list-apps", arguments: Array(arguments.dropFirst()), result: .listApps)
    case "call":
        return try parseCall(arguments: Array(arguments.dropFirst()))
    case "turn-ended":
        return try parseTurnEnded(arguments: Array(arguments.dropFirst()))
    case "snapshot":
        return try parseSnapshot(arguments: Array(arguments.dropFirst()))
    default:
        if first.hasPrefix("-") {
            throw CairnCLIError(message: "Unknown option: \(first)", helpCommand: nil)
        }

        throw CairnCLIError(message: "Unknown command: \(first)", helpCommand: nil)
    }
}

public func cairnHelpText(command: String? = nil) -> String {
    switch command {
    case nil:
        return """
        Cairn

        Usage:
          cairn [command] [options]
          cairn

        Commands:
          mcp                  Start the stdio MCP server.
          doctor               Print permission status and launch onboarding if needed.
          list-apps            Print running or recently used apps.
          snapshot <app>       Print the current accessibility snapshot for an app.
          call <tool>           Call one tool, or run a JSON array of tool calls.
          turn-ended           Notify the running MCP process that the host turn ended.
          help [command]       Show general or command-specific help.
          version              Print the CLI version.

        Global options:
          -h, --help           Show help.
          -v, --version        Show version.

        Notes:
          Running without a command launches the permission onboarding app.
          Use `cairn help <command>` for command-specific help.
        """
    case "mcp":
        return """
        Usage:
          cairn mcp

        Start the stdio MCP server.
        """
    case "doctor":
        return """
        Usage:
          cairn doctor [--cursor]

        Print the current Accessibility and Screen Recording permission state.
        --cursor adds macOS 26, PATH, and ~/.cursor/mcp.json preflight for Cursor.
        If permissions are missing, this also launches the onboarding app.
        """
    case "list-apps":
        return """
        Usage:
          cairn list-apps

        Print running apps plus recently used apps that can be targeted by Computer Use.
        """
    case "snapshot":
        return """
        Usage:
          cairn snapshot <app>

        Arguments:
          <app>                App name or bundle identifier to inspect.

        Print the current accessibility snapshot for the target app.
        """
    case "call":
        return """
        Usage:
          cairn call <tool> [--args '<json-object>']
          cairn call <tool> [--args-file <path>]
          cairn call --calls '<json-array>' [--sleep <seconds>]
          cairn call --calls-file <path> [--sleep <seconds>]

        Examples:
          cairn call list_apps
          cairn call get_app_state --args '{"app":"TextEdit"}'
          cairn call --calls '[{"tool":"get_app_state","args":{"app":"TextEdit"}},{"tool":"press_key","args":{"app":"TextEdit","key":"Return"}}]'
          cairn call --calls-file examples/textedit-overlay-seq.json --sleep 0.5

        The JSON array form keeps all calls in one process so follow-up actions
        can reuse the app state and element indices captured by get_app_state.
        Sequence execution stops after the first tool result with isError=true.
        Sequence runs sleep \(formatCairnDelay(cairnDefaultInterCallDelay)) between successful operations by default.
        """
    case "turn-ended":
        return """
        Usage:
          cairn turn-ended [--previous-notify <argv>] [payload]

        Notify a running local MCP process that the current host turn has ended.
        Codex legacy notify appends the after-agent JSON payload as the last argument.
        """
    case "version":
        return """
        Usage:
          cairn version
          cairn --version
          cairn -v

        Print the CLI version.
        """
    case "help":
        return """
        Usage:
          cairn help [command]

        Show general help or help for a specific command.
        """
    default:
        return """
        Unknown help topic: \(command ?? "")

        \(cairnHelpText())
        """
    }
}

private func parseDoctor(arguments: [String]) throws -> CairnCLICommand {
    if arguments.count == 1, let option = arguments.first, option == "-h" || option == "--help" {
        return .help(command: "doctor")
    }

    var cursor = false
    for argument in arguments {
        switch argument {
        case "--cursor":
            cursor = true
        default:
            throw CairnCLIError(message: "doctor accepts only --cursor", helpCommand: "doctor")
        }
    }

    return .doctor(cursor: cursor)
}

private func parseSimpleCommand(
    name: String,
    arguments: [String],
    result: CairnCLICommand
) throws -> CairnCLICommand {
    if arguments.isEmpty {
        return result
    }

    if arguments.count == 1, let option = arguments.first, option == "-h" || option == "--help" {
        return .help(command: name)
    }

    throw CairnCLIError(message: "\(name) does not accept any arguments", helpCommand: name)
}

private func parseTurnEnded(arguments: [String]) throws -> CairnCLICommand {
    if arguments.count == 1, let option = arguments.first, option == "-h" || option == "--help" {
        return .help(command: "turn-ended")
    }

    var payload: String?
    var index = 0
    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--previous-notify":
            let valueIndex = index + 1
            guard valueIndex < arguments.count else {
                throw CairnCLIError(message: "--previous-notify requires a value", helpCommand: "turn-ended")
            }
            index = valueIndex
        case "-h", "--help":
            throw CairnCLIError(message: "turn-ended help must be requested as `cairn turn-ended --help`", helpCommand: "turn-ended")
        default:
            if argument.hasPrefix("-") {
                throw CairnCLIError(message: "Unknown turn-ended option: \(argument)", helpCommand: "turn-ended")
            }

            guard payload == nil else {
                throw CairnCLIError(message: "turn-ended accepts at most one payload argument", helpCommand: "turn-ended")
            }

            payload = argument
        }

        index += 1
    }

    return .turnEnded(payload: payload)
}

private func parseSnapshot(arguments: [String]) throws -> CairnCLICommand {
    if arguments.count == 1 {
        let value = arguments[0]
        if value == "-h" || value == "--help" {
            return .help(command: "snapshot")
        }

        return .snapshot(app: value)
    }

    if arguments.isEmpty {
        throw CairnCLIError(message: "snapshot requires an app name or bundle identifier", helpCommand: "snapshot")
    }

    throw CairnCLIError(message: "snapshot accepts exactly one <app> argument", helpCommand: "snapshot")
}

private func parseCall(arguments: [String]) throws -> CairnCLICommand {
    if arguments.count == 1, let option = arguments.first, option == "-h" || option == "--help" {
        return .help(command: "call")
    }

    var toolName: String?
    var argumentsJSON: String?
    var argumentsFile: String?
    var callsJSON: String?
    var callsFile: String?
    var interCallDelay = cairnDefaultInterCallDelay

    var index = 0
    while index < arguments.count {
        let argument = arguments[index]

        switch argument {
        case "--args":
            argumentsJSON = try parseOptionValue("--args", arguments: arguments, index: &index)
        case "--args-file":
            argumentsFile = try parseOptionValue("--args-file", arguments: arguments, index: &index)
        case "--calls":
            callsJSON = try parseOptionValue("--calls", arguments: arguments, index: &index)
        case "--calls-file":
            callsFile = try parseOptionValue("--calls-file", arguments: arguments, index: &index)
        case "--sleep":
            interCallDelay = try parseTimeIntervalOptionValue("--sleep", arguments: arguments, index: &index)
        case "-h", "--help":
            throw CairnCLIError(message: "call help must be requested as `cairn call --help`", helpCommand: "call")
        default:
            if argument.hasPrefix("-") {
                throw CairnCLIError(message: "Unknown call option: \(argument)", helpCommand: "call")
            }

            guard toolName == nil else {
                throw CairnCLIError(message: "call accepts at most one tool name", helpCommand: "call")
            }

            toolName = argument
        }

        index += 1
    }

    let hasSequenceInput = callsJSON != nil || callsFile != nil
    if hasSequenceInput {
        if callsJSON != nil, callsFile != nil {
            throw CairnCLIError(message: "Use either --calls or --calls-file, not both", helpCommand: "call")
        }

        if toolName != nil || argumentsJSON != nil || argumentsFile != nil {
            throw CairnCLIError(
                message: "call sequence does not accept a tool name, --args, or --args-file",
                helpCommand: "call"
            )
        }

        return .call(.sequence(
            callsJSON: callsJSON,
            callsFile: callsFile,
            interCallDelay: interCallDelay
        ))
    }

    if argumentsJSON != nil, argumentsFile != nil {
        throw CairnCLIError(message: "Use either --args or --args-file, not both", helpCommand: "call")
    }

    if interCallDelay != cairnDefaultInterCallDelay {
        throw CairnCLIError(
            message: "--sleep is only supported with --calls or --calls-file",
            helpCommand: "call"
        )
    }

    guard let toolName else {
        throw CairnCLIError(message: "call requires a tool name or --calls/--calls-file", helpCommand: "call")
    }

    return .call(.single(toolName: toolName, argumentsJSON: argumentsJSON, argumentsFile: argumentsFile))
}

private func parseOptionValue(
    _ option: String,
    arguments: [String],
    index: inout Int
) throws -> String {
    let valueIndex = index + 1
    guard valueIndex < arguments.count else {
        throw CairnCLIError(message: "\(option) requires a value", helpCommand: "call")
    }

    index = valueIndex
    return arguments[valueIndex]
}

private func parseTimeIntervalOptionValue(
    _ option: String,
    arguments: [String],
    index: inout Int
) throws -> TimeInterval {
    let rawValue = try parseOptionValue(option, arguments: arguments, index: &index)
    guard let value = Double(rawValue), value.isFinite, value >= 0 else {
        throw CairnCLIError(
            message: "\(option) requires a non-negative number of seconds",
            helpCommand: "call"
        )
    }

    return value
}

private func formatCairnDelay(_ delay: TimeInterval) -> String {
    if delay.rounded() == delay {
        return "\(Int(delay))s"
    }

    return "\(delay)s"
}
