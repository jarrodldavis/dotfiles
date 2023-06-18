// The Swift Programming Language
// https://docs.swift.org/swift-book
//
// Swift Argument Parser
// https://swiftpackageindex.com/apple/swift-argument-parser/documentation

import ArgumentParser

@main
struct DotFiles: AsyncParsableCommand {
    mutating func run() async throws {
        print("Hello, world!")
        try await Task.sleep(for: .seconds(2))
        print("Goodbye, world!")
    }
}
