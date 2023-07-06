import Foundation
import Logging
import System

private enum InteractivityError: Error {
    case unsuccessfulBackgrounding(reason: Errno)
    case unsuccessfulForegrounding(reason: Errno)
}

private func makesyscall<each TArgs>(_ fn: (repeat each TArgs) -> Int32, _ args: repeat each TArgs) -> Result<Int32, Errno> {
    switch fn(repeat each args) {
    case -1: .failure(Errno(rawValue: errno))
    case let result: .success(result)
    }
}

func background() throws {
    logger.trace("attempting to background process")
    switch makesyscall(setsid) {
    case .failure(let error):
        logger.error("failed to background process", error: error)
        throw InteractivityError.unsuccessfulBackgrounding(reason: error)
    case .success(let result):
        logger.trace("process backgrounded successfully", metadata: ["sessionID": "\(result)"])
    }
}

func foreground(pid: Int32) throws {
    logger.trace("attempting to foreground process", metadata: ["pid": "\(pid)"])
    switch makesyscall(tcsetpgrp, STDIN_FILENO, pid) {
    case .failure(let error):
        logger.error("failed to foreground process", error: error)
        throw InteractivityError.unsuccessfulForegrounding(reason: error)
    case .success(let result):
        logger.trace("process foregrounded successfully", metadata: ["result": "\(result)"])
        return
    }
}

struct InteractivityProber {
    static func getStatus() -> InteractivityStatus {
        let current = Self()
        let status = current._status
        logger.trace("probed interactivity status", metadata: [
            "interactivity": [
                "status": "\(status)",
                "pid": "\(current.currentProcessID)",
                "pgrp": "\(current.currentProcessGroupID)",
                "sid": "\(current.currentSessionID)",
                "tcpgrp": "\(current.controllingProcessGroupID)",
                "tcsid": "\(current.controllingSessionID)",
            ]
        ])
        return status
    }

    let currentProcessID = ProcessInfo.processInfo.processIdentifier

    let currentProcessGroupID = makesyscall(getpgrp)
    let currentSessionID = makesyscall(getsid, 0)

    let controllingProcessGroupID = makesyscall(tcgetpgrp, STDIN_FILENO)
    let controllingSessionID = makesyscall(tcgetsid, STDIN_FILENO)

    private var _status: InteractivityStatus {
        switch (currentProcessGroupID, currentSessionID, controllingProcessGroupID, controllingSessionID) {
        case (.failure(_), _, _, _),
             (_, .failure(_), _, _):
            return .unknown

        case (.success(let groupID), .success(let sessionID), .failure(_), _)
                where groupID == sessionID,
             (.success(let groupID), .success(let sessionID), _, .failure(_))
                where groupID == sessionID:
            return .backgroundLeader

        case (.success(_), .success(_), .failure(_), _),
             (.success(_), .success(_), _, .failure(_)):
            return .backgroundFollower

        case (.success(let current), .success(_), .success(let controlling), .success(_))
                where current == controlling:
            return .interactiveLeader

        case (.success(_), .success(let current), .success(_), .success(let controlling))
                where current == controlling:
            return .interactiveFollower

        case (.success(let groupID), .success(let sessionID), .success(_), .success(_))
                where groupID == sessionID:
            return .backgroundLeader

        case (.success(_), .success(_), .success(_), .success(_)):
            return .backgroundFollower
        }
    }

    private init() {}
}

enum InteractivityStatus {
    case interactiveFollower
    case interactiveLeader
    case backgroundFollower
    case backgroundLeader
    case unknown
}
