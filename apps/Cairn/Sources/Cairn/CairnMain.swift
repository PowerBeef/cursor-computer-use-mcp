import AppKit
import Darwin
import Foundation
import CairnKit

@main
enum CairnMain {
    @MainActor
    static func main() {
        do {
            try run()
        } catch let error as CairnCLIError {
            writeToStandardError(error.errorDescription ?? error.message)
            exit(EXIT_FAILURE)
        } catch let error as CairnError {
            writeToStandardError(error.errorDescription ?? String(describing: error))
            exit(EXIT_FAILURE)
        } catch {
            let message = (error as? LocalizedError)?.errorDescription ?? String(describing: error)
            writeToStandardError(message)
            exit(EXIT_FAILURE)
        }
    }

    @MainActor
    private static func run() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())

        if MacOSAppAgentProxy.isAgentInvocation(arguments: arguments) {
            try MacOSAppAgentProxy.runAgent(arguments: arguments)
            return
        }

        let command = try parseCairnCLI(arguments: arguments)

        if MacOSAppAgentProxy.shouldProxy(command: command) {
            exit(try MacOSAppAgentProxy.runProxy(command: command, arguments: arguments))
        }

        switch command {
        case .mcp:
            let service = CairnService()
            let server = StdioMCPServer(service: service)
            if VisualCursorSupport.isEnabled {
                try MainActor.assumeIsolated {
                    try MCPAppRuntime.run(server: server)
                }
            } else {
                try server.run()
            }
        case let .doctor(cursor):
            if cursor {
                let diagnostics = CursorDoctorDiagnostics.run(cursorMode: true)
                print(diagnostics.summary)
            } else {
                let permissions = PermissionDiagnostics.current()
                print(permissions.summary)
            }
            if !PermissionDiagnostics.current().missingPermissions.isEmpty {
                PermissionOnboardingApp.launch()
            }
        case .listApps:
            let service = CairnService()
            print(service.listApps().primaryText ?? "")
        case let .snapshot(app):
            let service = CairnService()
            print(try service.getAppState(app: app).primaryText ?? "")
        case let .call(invocation):
            if VisualCursorSupport.isEnabled {
                _ = NSApplication.shared.setActivationPolicy(.accessory)
            }
            let output = try runCairnCall(invocation)
            print(try output.jsonText())
            if output.hasToolError {
                exit(EXIT_FAILURE)
            }
        case .turnEnded:
            postCairnTurnEndedNotification()
            print("turn-ended acknowledged")
        case let .help(command):
            print(cairnHelpText(command: command))
        case .version:
            print(resolvedCairnVersion())
        case .launchOnboarding:
            if !PermissionDiagnostics.current().allGranted {
                PermissionOnboardingApp.launch()
            }
        }
    }

    private static func writeToStandardError(_ message: String) {
        guard let data = (message + "\n").data(using: .utf8) else {
            return
        }

        FileHandle.standardError.write(data)
    }
}
