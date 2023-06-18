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
        logger.info("Hello, world!")
        try await Task.sleep(for: .seconds(2))
        logger.info("Goodbye, world!")

        try await link {
            ".zshrc" --> "zshrc"
        }
    }
}
