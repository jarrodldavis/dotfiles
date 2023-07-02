import Foundation
import Logging
import System

private enum ProcessExecutorError: Error {
    case currentProcessGroupProbeFailure(reason: Errno)
    case failedToStart(reason: Error)
    case quasiInteractive(controllingProcessGroupID: Int32, currentProcessGroupID: Int32)
    case unsuccessfulForegrounding(reason: Errno)
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

        let isInteractive = try probeIsInteractive(level: level)

        logger.log(level: level, "starting process")
        do {
            try process.run()
        } catch {
            let error = ProcessExecutorError.failedToStart(reason: error)
            throw logger.error("failed to start process", error: error)
        }

        async let complete = withCheckedContinuation { process.terminationHandler = $0.resume }

        if isInteractive {
            logger.log(level: level, "attempting to foreground interactive process")
            guard tcsetpgrp(STDIN_FILENO, process.processIdentifier) == 0 else {
                let error = logger.error("failed to foreground process", error: Errno(rawValue: errno))
                logger.notice("attempting to terminate process")
                process.terminate()
                let _ = await complete
                logger.notice("process terminated")
                throw ProcessExecutorError.unsuccessfulForegrounding(reason: error)
            }
            logger.log(level: level, "process foregrounded successfully")
        } else {
            logger.log(level: level, "skipping foregrounding of non-interactive process")
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

    private static func probeIsInteractive(level: Logger.Level) throws -> Bool {
        logger.log(level: level, "probing controlling process status")

        let currentProcessGroupID = getpgrp()
        guard currentProcessGroupID != -1 else {
            let error = ProcessExecutorError.currentProcessGroupProbeFailure(reason: Errno(rawValue: errno))
            throw logger.error("failed to probe for current process group", error: error)
        }

        let controllingProcessGroupID = tcgetpgrp(STDIN_FILENO);
        guard controllingProcessGroupID != -1 else {
            logger.log(
                level: level,
                "could not probe for controlling process group",
                metadata: [
                    "reason": "\(Errno(rawValue: errno))"
                ]
            )
            return false
        }

        if controllingProcessGroupID != currentProcessGroupID {
            let error = ProcessExecutorError.quasiInteractive(
                controllingProcessGroupID: controllingProcessGroupID,
                currentProcessGroupID: currentProcessGroupID
            )

            throw logger.error("current process group is quasi-interactive", error: error)
        } else {
            logger.log(
                level: level,
                "current process group is controlling",
                metadata: [
                    "interactive": [
                        "controllingProcessGroupID": "\(controllingProcessGroupID)",
                        "currentProcessGroupID": "\(currentProcessGroupID)",
                    ]
                ]
            )
            return true
        }
    }
}
