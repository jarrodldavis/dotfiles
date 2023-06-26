import Logging
import PackageDescription

typealias ParserResult = (upperBound: String.Index, output: Version)?

fileprivate struct ParserArguments {
    let input: String
    let index: String.Index
    let bounds: Range<String.Index>

    var versionString: String { String(input[index...]) }

    var metadata: Logger.MetadataValue {
        let start = input.distance(from: input.startIndex, to: index)
        let boundsLower = input.distance(from: input.startIndex, to: bounds.lowerBound)
        let boundsUpper = input.distance(from: input.startIndex, to: bounds.upperBound)

        return [
            "fullInput": "\(input)",
            "startIndex": "\(start)",
            "versionString": "\(versionString)",
            "bounds": "\(boundsLower)...\(boundsUpper)",
        ]
    }
}

struct VersionParser: CustomConsumingRegexComponent {
    @TaskLocal fileprivate static var current: ParserArguments? = nil

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }
        return ["version": current.metadata]
    }

    public typealias RegexOutput = Version

    public func consuming(
        _ input: String,
        startingAt index: String.Index,
        in bounds: Range<String.Index>
    ) throws -> ParserResult {
        let args = ParserArguments(input: input, index: index, bounds: bounds)
        return Self.$current.withValue(args, operation: Self.parse)
    }

    private static func parse() -> ParserResult {
        let args = current!

        logger.debug("parsing version from input")

        if let version = Version(args.versionString) {
            logger.debug("parsed full version string")
            return (args.bounds.upperBound, version)
        }

        if let version = Version("\(args.versionString).0") {
            logger.debug("parsed partial (non-patch) version string")
            return (args.bounds.upperBound, version)
        }

        return nil
    }
}

extension RegexComponent where Self == VersionParser {
    static func version() -> Self {
        VersionParser()
    }
}
