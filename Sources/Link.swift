import Foundation

let fileManager = FileManager()

struct Link {
    private static let home = fileManager.homeDirectoryForCurrentUser
    private static let cwd = URL(string: fileManager.currentDirectoryPath)!

    let destination: URL
    let source: URL

    init(destination: String, source: String) {
        self.destination = URL(filePath: destination, directoryHint: .inferFromPath, relativeTo: Self.home)
        self.source = URL(filePath: source, directoryHint: .inferFromPath, relativeTo: Self.cwd)
    }
}

infix operator -->

extension String {
    static func --> (destination: String, source: String) -> Link {
        return Link(destination: destination, source: source)
    }
}

@resultBuilder
struct LinkCollectionBuilder {
    static func buildBlock(_ components: Link...) -> [Link] {
        components
    }
}

func link(@LinkCollectionBuilder _ links: () -> [Link]) async throws {
    for link in links() {
        print(link)
    }
}
