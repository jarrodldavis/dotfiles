// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Foundation
import Logging
import System

fileprivate let defaultLocal = URL.homeDirectory.appending(component: ".dotfiles", directoryHint: .isDirectory)
fileprivate let defaultRemote = URL(string: "https://github.com/jarrodldavis/dotfiles.git")!

var logger = Logger(label: "com.jarrodldavis.DotFiles")

@main
struct DotFiles: AsyncParsableCommand {
    @Option(
        help: .init(
            "Specifies the local directory to clone the dotfiles repository to.",
            discussion: "Default: \(FilePath(defaultLocal)!.string)",
            valueName: "directory"
        ),
        completion: .directory,
        transform: { URL(filePath: $0, directoryHint: .isDirectory) }
    )
    var local: URL = defaultLocal

    @Option(
        help: .init(
            "Specifies the remote repository to clone the dotfiles repository from.",
            discussion: "Default: \(defaultRemote.absoluteString)",
            valueName: "url"
        ),
        transform: { try URL(string: $0) ?? { throw ValidationError("invalid URL") }() }
    )
    var remote: URL = defaultRemote

    @Flag(name: .shortAndLong, help: "Increases the verbosity of logs.")
    var verbosity: Int

    mutating func run() async throws {
        LoggingSystem.bootstrap(
            StreamLogHandler.standardOutput,
            metadataProvider: .multiplex([
                XcodeToolsInstaller.metadataProvider,
                LinkCreator.metadataProvider,
                ProcessExecutor.metadataProvider,
                RemoteScriptRunner.metadataProvider,
                RepositoryCloner.metadataProvider,
                SudoSession.metadataProvider,
                VersionParser.metadataProvider,
            ])
        )

        switch verbosity {
        case 1:
            logger.logLevel = .debug
            logger.debug("debug logs enabled")
        case 2:
            logger.logLevel = .trace
            logger.trace("trace logs enabled")
        default:
            break
        }

        let sudoSession = try await SudoSession.start()

        try await XcodeToolsInstaller.install()
        try await RepositoryCloner.clone(from: remote, to: local)

        try LinkCreator.create {
            local / "zshrc" <- ".zshrc"
        }

        try await RemoteScriptRunner.run(.homebrewInstaller, using: .bash, with: ["CI": "true"])

        try await sudoSession.finish()
    }
}
