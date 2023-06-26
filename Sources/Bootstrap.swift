import Foundation
import Logging
import RegexBuilder
import System

fileprivate enum BootstrapperError: Error {
    case incompleteInstallation(underlying: Error)
    case noCLTCandidate
}

fileprivate let git = URL(filePath: "/Library/Developer/CommandLineTools/usr/bin/git")
fileprivate let placeholder = "/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
fileprivate let label = Regex {
    "* Label: "
    Capture {
        "Command Line Tools for Xcode-"
        Capture(.version())
    }
}

struct Bootstrapper {
    @TaskLocal private static var current: Bool = false

    static let metadataProvider = Logger.MetadataProvider {
        guard current else { return [:] }
        return ["bootstrap": "true"]
    }

    static func pull() async throws {
        do {
            try await $current.withValue(true, operation: installTools)
        } catch {
            throw logger.error("failed to install Xcode Command Line Tools", error: error)
        }
    }

    private static func installTools() async throws {
        logger.info("finding Xcode Command Line Tools installation candidates")

        FileManager.default.createFile(atPath: placeholder, contents: nil)

        let output = try await ProcessExecutor.captureOutput(of: "/usr/sbin/softwareupdate", with: "-l")
        let result = try await output.stdout.lines
            .compactMap { try label.wholeMatch(in: $0) }
            .map {
                let result = (label: String($0.output.1), version: $0.output.2)
                logger.debug("found candidate command line tools: \(result.label)")
                return result
            }
            .max { $0.version < $1.version }

        guard let result else {
            throw logger.error(
                "could not find command line tools installation candidate",
                error: BootstrapperError.noCLTCandidate
            )
        }

        logger.info("installing \(result.label)")

        try await ProcessExecutor.execute(command: "/usr/sbin/softwareupdate", with: "-i", result.label)

        try FileManager.default.removeItem(atPath: placeholder)

        do {
            guard try git.checkResourceIsReachable() else {
                throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: FilePath(git)!.string])
            }
        } catch {
            throw BootstrapperError.incompleteInstallation(underlying: error)
        }
    }
}
