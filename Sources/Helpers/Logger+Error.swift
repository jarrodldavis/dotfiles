import Logging

extension Logger {
    @discardableResult
    func error<T: Error>(
        _ message: @autoclosure () -> Message,
        error: T,
        file: String = #fileID,
        function: String = #function,
        line: UInt = #line
    ) -> T {
        self.error(message(), metadata: ["error": "\(error)"], file: file, function: function, line: line)
        return error
    }
}
