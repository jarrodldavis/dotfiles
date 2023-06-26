import Foundation
import Logging
import System

struct RemoteScript {
    fileprivate let source: URL
    fileprivate let shell: URL
    fileprivate let environment: [String: String]?
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

    static func run(_ script: URL, using shell: URL, with environment: [String: String]? = nil) async throws {
        try await $current.withValue(RemoteScript(source: script, shell: shell, environment: environment), operation: run)
    }

    private static func run() async throws {
        let script = current!

        logger.info("running remote script")

        let contents = try await download(from: script.source)
        try await ProcessExecutor.execute(contents: contents, using: script.shell, with: script.environment)

        logger.info("remote script executed successfully")
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
