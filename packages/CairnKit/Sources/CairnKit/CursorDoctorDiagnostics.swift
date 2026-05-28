import Foundation

public struct CursorDoctorDiagnostics: Sendable {
    public let permissionSummary: String
    public let macOSVersionOK: Bool
    public let macOSVersionLine: String
    public let cairnOnPath: Bool
    public let pathLine: String
    public let mcpWarnings: [String]

    public var summary: String {
        ([
            permissionSummary,
            macOSVersionLine,
            pathLine,
        ] + mcpWarnings).joined(separator: "\n")
    }

    public static func run(cursorMode: Bool) -> CursorDoctorDiagnostics {
        let permissions = PermissionDiagnostics.current()
        let version = ProcessInfo.processInfo.operatingSystemVersion
        let macOSOK = version.majorVersion >= 26
        let versionLine = "macOS: \(version.majorVersion).\(version.minorVersion).\(version.patchVersion) (required: 26+)"

        let whichPath = runWhich("cairn")
        let onPath = whichPath != nil

        var warnings: [String] = []
        if cursorMode {
            warnings.append(contentsOf: scanCursorMCPConfigs())
        }

        return CursorDoctorDiagnostics(
            permissionSummary: permissions.summary + " Grant Accessibility and Screen Recording to Cairn.app (not Terminal/Cursor).",
            macOSVersionOK: macOSOK,
            macOSVersionLine: versionLine + (macOSOK ? "" : " — upgrade required for this repository's native build."),
            cairnOnPath: onPath,
            pathLine: onPath
                ? "PATH: cairn found at \(whichPath!)"
                : "PATH: cairn not found (required for Cursor Automations and MCP).",
            mcpWarnings: warnings
        )
    }

    private static func scanCursorMCPConfigs() -> [String] {
        var warnings: [String] = []
        let home = FileManager.default.homeDirectoryForCurrentUser
        var paths = [
            home.appendingPathComponent(".cursor/mcp.json"),
            URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(".cursor/mcp.json"),
        ]

        if let projectRoot = ProcessInfo.processInfo.environment["CAIRN_PROJECT_ROOT"]?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !projectRoot.isEmpty
        {
            let projectMCP = URL(fileURLWithPath: projectRoot, isDirectory: true)
                .appendingPathComponent(".cursor/mcp.json")
            if !paths.contains(projectMCP) {
                paths.append(projectMCP)
            }
        }

        for path in paths {
            guard let data = try? Data(contentsOf: path),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let servers = json["mcpServers"] as? [String: Any]
            else {
                continue
            }

            if servers["computer-use-mcp"] != nil {
                warnings.append("MCP (\(path.lastPathComponent)): disable legacy computer-use-mcp (single computer tool). Use cairn (9 tools).")
            }

            let computerUseEntries = servers.keys.filter {
                $0.localizedCaseInsensitiveContains("computer-use") || $0.localizedCaseInsensitiveContains("computer_use")
            }
            if computerUseEntries.count > 1 {
                warnings.append("MCP (\(path.lastPathComponent)): multiple Computer Use servers enabled (\(computerUseEntries.joined(separator: ", "))). Enable only cairn.")
            }

            if servers["cairn"] == nil, path.lastPathComponent == "mcp.json" {
                warnings.append("MCP: cairn not configured in \(path.path). Run cairn install-cursor-mcp.")
            }
        }

        return warnings
    }

    private static func runWhich(_ command: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()
        do {
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else {
                return nil
            }
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return path?.isEmpty == false ? path : nil
        } catch {
            return nil
        }
    }
}
