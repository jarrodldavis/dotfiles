import Foundation
import Logging
import System

private enum ProcessExecutorError: Error {
    case unsuccessfulInteractivityProbe
    case failedToStart(reason: Error)
    case unsuccessfulTermination(reason: Process.TerminationReason, status: Int32)
}

struct ProcessOutput {
    let stdout: FileHandle.AsyncBytes
    let stderr: FileHandle.AsyncBytes

    fileprivate init(stdout: Pipe, stderr: Pipe) {
        // TODO: Make sure this doesn't leak.
        self.stdout = stdout.fileHandleForReading.bytes
        self.stderr = stderr.fileHandleForReading.bytes
    }
}

extension Process {
    var executablePath: String? {
        guard let executableURL, let executablePath = FilePath(executableURL) else { return nil }
        return executablePath.string
    }
}

struct ProcessExecutor {
    @TaskLocal private static var current: Process?

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }

        return [
            "process": [
                "pid": current.processIdentifier == 0 ? "<none>" : "\(current.processIdentifier)",
                "executable": .stringConvertible(current.executablePath, else: "<none>"),
                "arguments": .array(current.arguments, else: "<none>"),
            ]
        ]
    }

    static func captureOutput(of command: String, with arguments: String...) async throws -> ProcessOutput {
        let process = Process()
        process.executableURL = URL(filePath: command, directoryHint: .notDirectory)
        process.arguments = arguments

        let stdout = Pipe();
        let stderr = Pipe();
        process.standardOutput = stdout
        process.standardError = stderr

        try await $current.withValue(process) {
            try await execute(.info)
        }

        return ProcessOutput(stdout: stdout, stderr: stderr)
    }

    static func execute(contents: String, using shell: URL, with environment: [String: String]? = nil) async throws {
        let process = Process()
        process.executableURL = shell
        process.arguments = ["-c", contents]

        if let environment {
            process.environment = ProcessInfo.processInfo.environment.merging(environment) { $1 }
        }

        try await $current.withValue(process) {
            try await execute(.info)
        }
    }

    static func execute(command: String, with arguments: String..., at level: Logger.Level = .info) async throws {
        let process = Process()
        process.executableURL = URL(filePath: command, directoryHint: .notDirectory)
        process.arguments = arguments
        try await $current.withValue(process) {
            try await execute(level)
        }
    }

    private static func execute(_ level: Logger.Level) async throws {
        let process = current!

        let interactivityStatus = InteractivityProber.getStatus()

        guard interactivityStatus != .unknown else {
            logger.error("failed to probe interactivity status")
            throw ProcessExecutorError.unsuccessfulInteractivityProbe
        }

        if interactivityStatus == .backgroundFollower {
            try background()
        }

        logger.log(level: level, "starting process")
        do {
            try process.run()
        } catch {
            let error = ProcessExecutorError.failedToStart(reason: error)
            throw logger.error("failed to start process", error: error)
        }
        logger.log(level: min(.debug, level), "started process successfully")

        async let complete = withCheckedContinuation { process.terminationHandler = $0.resume }

        if interactivityStatus == .interactiveLeader {
            do {
                try foreground(pid: process.processIdentifier)
            } catch {
                logger.notice("attempting to terminate process")
                process.terminate()
                let _ = await complete
                logger.notice("process terminated")
                throw error
            }
        } else {
            logger.log(level: min(.debug, level), "skipping foregrounding of non-interactive or non-leader process")
        }

        defer {
            if interactivityStatus == .interactiveLeader {
                do {
                    logger.trace("restoring foreground process")
                    try foreground(pid: ProcessInfo.processInfo.processIdentifier)
                    logger.trace("foreground process restored successfully")
                } catch {
                    logger.warning("failed to restore foreground process", metadata: ["reason": "\(error)"])
                }
            }
        }

        let _ = await complete
        logger.log(level: level, "process finished")

        let reason = process.terminationReason
        let status = process.terminationStatus

        guard reason == .exit, status == 0 else {
            let error = ProcessExecutorError.unsuccessfulTermination(reason: reason, status: status)
            throw logger.error("process terminated unsuccessfully", error: error)
        }
    }
}
