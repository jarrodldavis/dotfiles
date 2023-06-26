import Foundation
import Logging

extension Logger.MetadataValue {
    static func array(_ array: [String]) -> Self {
        return Self.array(array.map {
            if $0.count <= 100 {
                return .string($0)
            } else {
                return "\($0.prefix(100))…"
            }
        })
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
