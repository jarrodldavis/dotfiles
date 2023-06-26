import Foundation
import Logging

extension Logger.MetadataValue {
    static func array(_ array: [String]) -> Self {
        return Self.array(array.map(Self.string))
    }

    static func array(_ array: [String]?, else fallback: @autoclosure () -> Self) -> Self {
        guard let array else { return fallback() }
        return Self.array(array)
    }

    static func stringConvertible(
        _ convertible: Optional<CustomStringConvertible & Sendable>,
        else fallback: @autoclosure () -> Self
    ) -> Self {
        guard let convertible else { return fallback() }
        return Self.stringConvertible(convertible)
    }
}
