import Logging

extension Logger {
    func error(
        _ message: @autoclosure () -> Message,
        error: Error,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) {
        self.error(message(), metadata: ["error": "\(error)"], file: file, function: function, line: line)
    }
}
