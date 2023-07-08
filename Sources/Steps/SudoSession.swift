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
            logger.debug("sudo keep-alive session primed successfully")
        }

        let keepalive = Task {
            try await $current.withValue(true) {
                while !Task.isCancelled {
                    try await Task.sleep(for: .seconds(60))
                    logger.trace("continuing sudo keep-alive session")
                    // TODO: Make "sidecar" execution to prevent leader stealing.
                    try await ProcessExecutor.execute(command: "/usr/bin/sudo", with: "-vn", at: .trace)
                    logger.trace("sudo keep-alive session continued successfully")
                }

                logger.debug("sudo keep-alive session cancelled")
            }
        }

        return Self(task: keepalive)
    }
}
