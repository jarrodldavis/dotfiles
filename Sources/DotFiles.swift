// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Logging

var logger = Logger(label: "com.jarrodldavis.DotFiles")

@main
struct DotFiles: AsyncParsableCommand {
    @Flag(name: .shortAndLong, help: "Increases the verbosity of logs.")
    var verbosity: Int

    mutating func run() async throws {
        LoggingSystem.bootstrap(
            StreamLogHandler.standardOutput,
            metadataProvider: .multiplex([
                Bootstrapper.metadataProvider,
                LinkCreator.metadataProvider,
                ProcessExecutor.metadataProvider,
                RemoteScriptRunner.metadataProvider,
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

        try await Bootstrapper.pull()

        try LinkCreator.create {
            "zshrc" <- ".zshrc"
        }

        try await RemoteScriptRunner.run(.homebrewInstaller, using: .bash, with: ["CI": "true"])

        try await sudoSession.finish()
    }
}
