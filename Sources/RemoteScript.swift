import Foundation
import Logging
import System

struct RemoteScript {
    fileprivate let source: URL
    fileprivate let shell: URL
}

fileprivate extension RemoteScript {
    var shellPath: String { FilePath(shell)!.string }

    var metadata: Logger.MetadataValue {
        return ["source": "\(source.absoluteString)", "shell": "\(shellPath)"]
    }
}

private enum RemoteScriptError: Error {
    case unexpectedResponseType(response: URLResponse)
    case unsuccessfulStatusCode(statusCode: Int)
    case unsuccessfulForegrounding(reason: Errno)
    case unsuccessfulTermination(reason: Process.TerminationReason, status: Int32)
}

extension Process.TerminationReason: CustomStringConvertible {
    public var description: String {
        switch self {
        case .exit:
            return "exit"
        case .uncaughtSignal:
            return "uncaught signal"
        @unknown default:
            return "unknown"
        }
    }
}

struct RemoteScriptRunner {
    @TaskLocal private static var current: RemoteScript?

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }
        return ["script": current.metadata]
    }

    static func run(_ script: URL, using shell: URL) async throws {
        try await $current.withValue(RemoteScript(source: script, shell: shell), operation: run)
    }

    private static func run() async throws {
        let script = current!

        logger.info("running remote script")

        let contents = try await download(from: script.source)
        try await ProcessExecutor.execute(contents: contents, using: script.shell)

        logger.info("remote script executed successfully")
    }
}

fileprivate struct ProcessExecutor {
    @TaskLocal private static var current: Process?

    static func execute(contents: String, using shell: URL) async throws {
        let process = Process()
        process.executableURL = shell
        process.arguments = ["-c", contents]
        try await $current.withValue(process, operation: execute)
    }

    private static func execute() async throws {
        let process = current!

        async let complete = withCheckedContinuation { process.terminationHandler = $0.resume }

        do {
            try process.run()
        } catch {
            throw logger.error("failed to start script execution", error: error)
        }

        guard tcsetpgrp(STDIN_FILENO, process.processIdentifier) == 0 else {
            let error = logger.error(
                "failed to foreground shell process, attempting to terminate...",
                error: RemoteScriptError.unsuccessfulForegrounding(reason: Errno(rawValue: errno))
            )
            process.terminate()
            let _ = await complete
            logger.notice("shell process terminated")
            throw error
        }

        let _ = await complete

        let reason = process.terminationReason
        let status = process.terminationStatus

        guard reason == .exit, status == 0 else {
            let error = RemoteScriptError.unsuccessfulTermination(reason: reason, status: status)
            throw logger.error("script execution failed", error: error)
        }
    }
}

fileprivate func download(from source: URL) async throws -> String {
    logger.debug("downloading script contents from source")

    let contents: String

    do {
        let (data, response) = try await URLSession.shared.data(from: source)

        logger.debug(
            "finished downloading script contents",
            metadata: ["data": "\(data)", "response": "\(response)"]
        )

        guard let response = response as? HTTPURLResponse else {
            throw RemoteScriptError.unexpectedResponseType(response: response)
        }

        guard response.statusCode == 200 else {
            throw RemoteScriptError.unsuccessfulStatusCode(statusCode: response.statusCode)
        }

        contents = String(decoding: data, as: UTF8.self)
    } catch {
        throw logger.error("failed to download script contents", error: error)
    }

    logger.debug("successfully fetched script contents", metadata: ["contents": "\(contents)"])

    return contents
}

extension URL {
    static let bash = URL(filePath: "/bin/bash")

    static let homebrewInstaller = URL(string: "https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh")!
}
