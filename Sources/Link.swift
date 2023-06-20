import Foundation
import Logging
import System

private let fileManager = FileManager.default

struct Link: CustomStringConvertible {
    fileprivate let source: URL
    fileprivate let target: URL

    var description: String { "\(targetPath) -> \(sourcePath)" }
}

fileprivate extension Link {
    var sourcePath: String { FilePath(source)!.string }
    var sourceDirectory: URL { source.deletingLastPathComponent() }

    var targetPath: String { FilePath(target)!.string }
    var targetDirectory: URL { target.deletingLastPathComponent() }

    var metadata: Logger.MetadataValue { ["source": "\(sourcePath)", "target": "\(targetPath)"] }

    init(source: String, target: String) {
        self.source = URL(filePath: source, relativeTo: .currentDirectory())
        self.target = URL(filePath: target, relativeTo: .homeDirectory)
    }
}

infix operator <-

extension String {
    static func <- (source: String, target: String) -> Link { Link(source: source, target: target) }
}

@resultBuilder
struct LinkCollectionBuilder {
    static func buildBlock(_ components: Link...) -> [Link] { components }
}

struct LinkCreator {
    @TaskLocal private static var current: Link?

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }
        return ["link": current.metadata]
    }

    static func create(@LinkCollectionBuilder _ links: () -> [Link]) throws {
        for link in links() {
            try $current.withValue(link, operation: create)
        }
    }

    private static func create() throws {
        let link = current!

        logger.debug("creating symbolic link")

        do {
            // Creating a symbolic link doesn't check if the source actually exists, so check it manually.
            guard try link.source.checkResourceIsReachable() else {
                throw CocoaError(.fileReadNoSuchFile, userInfo: [NSFilePathErrorKey: link.sourcePath])
            }

            do {
                try fileManager.createSymbolicLink(at: link.target, withDestinationURL: link.source)
            } catch CocoaError.fileWriteFileExists {
                logger.debug("overwriting existing item at target file path")
                try fileManager.removeItem(at: link.target)
                try fileManager.createSymbolicLink(at: link.target, withDestinationURL: link.source)
            } catch CocoaError.fileNoSuchFile {
                logger.debug("creating parent directories for target file path")
                try fileManager.createDirectory(at: link.targetDirectory, withIntermediateDirectories: true)
                try fileManager.createSymbolicLink(at: link.target, withDestinationURL: link.source)
            }
        } catch {
            throw logger.error("failed to create symbolic link", error: error)
        }

        logger.info("successfully created symbolic link: \(link)")
    }
}
