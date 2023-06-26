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
                LinkCreator.metadataProvider,
                RemoteScriptRunner.metadataProvider,
                ProcessExecutor.metadataProvider,
            ])
        )

        try LinkCreator.create {
            "zshrc" <- ".zshrc"
        }

        try await RemoteScriptRunner.run(.homebrewInstaller, using: .bash)
    }
}
