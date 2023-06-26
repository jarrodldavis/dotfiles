import Foundation
import Logging

struct SudoSession {
    @TaskLocal private static var current: Bool = false

    static let metadataProvider = Logger.MetadataProvider {
        guard current else { return [:] }
        return ["sudo-session": "true"]
    }

    private let task: Task<(), Error>

    private init(task: Task<(), Error>) {
        self.task = task
    }

    func finish() async throws {
        self.task.cancel()

        do {
            try await self.task.value
        } catch is CancellationError {
            return
        }
    }

    static func start() async throws -> Self {
        try await $current.withValue(true) {
            logger.info("priming sudo keep-alive session")
            try await ProcessExecutor.execute(command: "/usr/bin/sudo", with: "-v")
        }

        let keepalive = Task {
            try await $current.withValue(true) {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(60))
                    logger.debug("continuing sudo keep-alive session")
                    try await ProcessExecutor.execute(command: "/usr/bin/sudo", with: "-vn", at: .debug)
                }
            }
        }

        return Self(task: keepalive)
    }
}
