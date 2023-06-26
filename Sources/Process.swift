import Foundation
import Logging
import System

private enum ProcessExecutorError: Error {
    case unsuccessfulForegrounding(reason: Errno)
    case unsuccessfulTermination(reason: Process.TerminationReason, status: Int32)
}

struct ProcessExecutor {
    @TaskLocal private static var current: Process?

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }

        return [
            "process": [
                "pid": current.processIdentifier == 0 ? "<none>" : "\(current.processIdentifier)",
                "executableURL": .stringConvertible(current.executableURL, else: "<none>"),
                "arguments": .array(current.arguments, else: "<none>"),
            ]
        ]
    }

    static func execute(contents: String, using shell: URL, with environment: [String: String]? = nil) async throws {
        let process = Process()
        process.executableURL = shell
        process.arguments = ["-c", contents]

        if let environment {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        }

        try await $current.withValue(process, operation: execute)
    }

    static func execute(command: String, with arguments: String...) async throws {
        let process = Process()
        process.executableURL = URL(filePath: command, directoryHint: .notDirectory)
        process.arguments = arguments
        try await $current.withValue(process, operation: execute)
    }

    private static func execute() async throws {
        let process = current!

        async let complete = withCheckedContinuation { process.terminationHandler = $0.resume }

        logger.info("starting process")
        do {
            try process.run()
        } catch {
            throw logger.error("failed to start process", error: error)
        }

        guard tcsetpgrp(STDIN_FILENO, process.processIdentifier) == 0 else {
            let error = logger.error(
                "failed to foreground process, attempting to terminate...",
                error: ProcessExecutorError.unsuccessfulForegrounding(reason: Errno(rawValue: errno))
            )
            process.terminate()
            let _ = await complete
            logger.notice("process terminated")
            throw error
        }

        let _ = await complete
        logger.debug("process terminated")

        let reason = process.terminationReason
        let status = process.terminationStatus

        guard reason == .exit, status == 0 else {
            let error = ProcessExecutorError.unsuccessfulTermination(reason: reason, status: status)
            throw logger.error("process terminated unsuccessfully", error: error)
        }
    }
}
