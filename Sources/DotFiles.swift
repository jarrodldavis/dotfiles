// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser
import Logging

let logger = Logger(label: "com.jarrodldavis.DotFiles")

@main
struct DotFiles: AsyncParsableCommand {
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

        let sudoSession = try await SudoSession.start()

        try await Bootstrapper.pull()

        try LinkCreator.create {
            "zshrc" <- ".zshrc"
        }

        try await RemoteScriptRunner.run(.homebrewInstaller, using: .bash, with: ["CI": "true"])

        try await sudoSession.finish()
    }
}
