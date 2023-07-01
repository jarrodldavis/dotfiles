import Foundation
import Logging
import RegexBuilder
import System

fileprivate struct Repository: CustomStringConvertible {
    private let local: URL
    private let remote: URL

    var localPath: String { FilePath(local)!.string }
    var remoteString: String { remote.absoluteString }

    var description: String { "\(remoteString) -> \(localPath)" }
    var metadata: Logger.MetadataValue { ["local": "\(localPath)", "remote": "\(remoteString)"] }

    init(local: URL, remote: URL) {
        self.local = local
        self.remote = remote
    }
}

struct RepositoryCloner {
    @TaskLocal private static var current: Repository? = nil

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }
        return ["repository": current.metadata]
    }

    static func clone(from remote: URL, to local: URL) async throws {
        do {
            try await $current.withValue(Repository(local: local, remote: remote), operation: clone)
        } catch {
            throw logger.error("failed to clone dotfiles repository", error: error)
        }
    }

    private static func clone() async throws {
        let pull = current!

        if FileManager.default.fileExists(atPath: pull.localPath) {
            logger.info("local repository already exists; probing current status")
            try await ProcessExecutor.execute(command: "/usr/bin/git", with: "-C", pull.localPath, "status")
        } else {
            logger.info("cloning remote repository: \(pull)")
            try await ProcessExecutor.execute(command: "/usr/bin/git", with: "clone", pull.remoteString, pull.localPath)
        }
    }
}
