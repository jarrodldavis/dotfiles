import Foundation
import Logging
import System

private func makesyscall<each TArgs>(
    _ fn: (repeat each TArgs) -> Int32,
    _ args: repeat each TArgs
) -> Result<Int32, Errno> {
    switch fn(repeat each args) {
    case -1: .failure(Errno(rawValue: errno))
    case let result: .success(result)
    }
}

enum ExecutionSessionError: Error {
    case mismatchedBackgrounding(expected: Int32, actual: Int32)
    case mismatchedForegrounding(expected: Int32, actual: Int32)
    case unsuccessfulBackgrounding(reason: Errno)
    case unsuccessfulForegrounding(reason: Errno)
    case unsuccessfulInteractivityProbe
}

enum InteractivityStatus {
    case backgroundFollower(groupID: Int32, sessionID: Int32)
    case backgroundLeader(groupID: Int32, sessionID: Int32)
    case foregroundFollower(groupID: Int32, sessionID: Int32)
    case foregroundLeader(groupID: Int32, sessionID: Int32)
    case unknown
}

class InteractivityState {
    private var controllingProcessGroupID: Result<Int32, Errno>
    private var controllingSessionID: Result<Int32, Errno>

    private let targetProcessID: Int32
    private var targetProcessGroupID: Result<Int32, Errno>
    private var targetSessionID: Result<Int32, Errno>

    var targetStatus: InteractivityStatus {
        resolveStatus(
            targetProcessGroupID: targetProcessGroupID,
            targetSessionID: targetSessionID,
            controllingProcessGroupID: controllingProcessGroupID,
            controllingSessionID: controllingSessionID
        )
    }

    private let currentProcessID: Int32
    private var currentProcessGroupID: Result<Int32, Errno>
    private var currentSessionID: Result<Int32, Errno>

    var currentStatus: InteractivityStatus {
        resolveStatus(
            targetProcessGroupID: currentProcessGroupID,
            targetSessionID: currentSessionID,
            controllingProcessGroupID: controllingProcessGroupID,
            controllingSessionID: controllingSessionID
        )
    }

    var metadata: Logger.MetadataValue {
        if targetProcessID == currentProcessID {
            [
                "tcpgrp": "\(controllingProcessGroupID)",
                "tcsid": "\(controllingSessionID)",
                "pid": "\(currentProcessID)",
                "pgrp": "\(currentProcessGroupID)",
                "sid": "\(currentSessionID)",
                "status": "\(currentStatus)",
            ]
        } else {
            [
                "tcpgrp": "\(controllingProcessGroupID)",
                "tcsid": "\(controllingSessionID)",
                "current": [
                    "pid": "\(currentProcessID)",
                    "pgrp": "\(currentProcessGroupID)",
                    "sid": "\(currentSessionID)",
                    "status": "\(currentStatus)",
                ],
                "target": [
                    "pid": "\(targetProcessID)",
                    "pgrp": "\(targetProcessGroupID)",
                    "sid": "\(targetSessionID)",
                    "status": "\(targetStatus)",
                ],
            ]
        }
    }

    init(pid: Int32) {
        targetProcessID = pid
        currentProcessID = ProcessInfo.processInfo.processIdentifier

        // TODO: Is there a way to init using `refresh()`?
        controllingProcessGroupID = makesyscall(tcgetpgrp, STDIN_FILENO)
        controllingSessionID = makesyscall(tcgetsid, STDIN_FILENO)
        targetProcessGroupID = makesyscall(getpgid, targetProcessID)
        targetSessionID = makesyscall(getsid, targetProcessID)
        currentProcessGroupID = makesyscall(getpgrp)
        currentSessionID = makesyscall(getsid, 0)
    }

    func refresh() {
        controllingProcessGroupID = makesyscall(tcgetpgrp, STDIN_FILENO)
        controllingSessionID = makesyscall(tcgetsid, STDIN_FILENO)
        targetProcessGroupID = makesyscall(getpgid, targetProcessID)
        targetSessionID = makesyscall(getsid, targetProcessID)
        currentProcessGroupID = makesyscall(getpgrp)
        currentSessionID = makesyscall(getsid, 0)
    }

    func promote() throws {
        switch targetStatus {
        case .backgroundFollower(let groupID, _):
            guard self.currentProcessID == self.targetProcessID else {
                logger.trace("maintaining background follower")
                return
            }

            logger.trace("promoting background follower to leader")

            let result = switch makesyscall(setsid) {
            case .failure(let error):
                logger.error("`setsid` failed", error: error)
                throw ExecutionSessionError.unsuccessfulBackgrounding(reason: error)
            case .success(let result):
                result
            }

            logger.trace("`setsid` completed", metadata: ["result": "\(result)"])

            self.refresh()

            guard case .backgroundLeader = self.targetStatus else {
                switch self.targetSessionID {
                case .success(let sessionID):
                    logger.error("process promotion failed despite `setsid` success")
                    throw ExecutionSessionError.mismatchedBackgrounding(expected: groupID, actual: sessionID)
                case .failure(let error):
                    logger.error("failed to verify process promotion", error: error)
                    throw ExecutionSessionError.unsuccessfulBackgrounding(reason: error)
                }
            }

            logger.trace("process promoted successfully")

        case .backgroundLeader:
            logger.trace("maintaining background leader")

        case .foregroundFollower(let groupID, _):
            guard self.currentProcessID == self.targetProcessID || self.currentProcessGroupID == self.controllingProcessGroupID else {
                // TODO: Make this an error by default and allow opting into refusal ("sidecar" execution).
                logger.trace("refusing to steal leadership from other foreground child process")
                return
            }

            logger.trace("promoting foreground follower to leader")

            let result = switch makesyscall(tcsetpgrp, STDIN_FILENO, groupID) {
            case .success(let result):
                result
            case .failure(let error):
                logger.error("`tcsetpgrp` failed", error: error)
                throw ExecutionSessionError.unsuccessfulForegrounding(reason: error)
            }

            logger.trace("`tcsetpgrp` completed", metadata: ["result": "\(result)"])

            self.refresh()

            guard case .foregroundLeader = self.targetStatus else {
                switch self.controllingProcessGroupID {
                case .success(let controllingGroupID):
                    logger.error("process promotion failed despite `tcsetpgrp` success")
                    throw ExecutionSessionError.mismatchedForegrounding(expected: groupID, actual: controllingGroupID)
                case .failure(let error):
                    logger.error("failed to verify process promotion", error: error)
                    throw ExecutionSessionError.unsuccessfulForegrounding(reason: error)
                }
            }

            logger.trace("process promoted successfully")

        case .foregroundLeader:
            logger.trace("maintaining foreground leader")

        case .unknown:
            logger.error("failed to probe interactivity status")
            throw ExecutionSessionError.unsuccessfulInteractivityProbe
        }
    }
}

private func resolveStatus(
    targetProcessGroupID: Result<Int32, Errno>,
    targetSessionID: Result<Int32, Errno>,
    controllingProcessGroupID: Result<Int32, Errno>,
    controllingSessionID: Result<Int32, Errno>
) -> InteractivityStatus {
    switch (targetProcessGroupID, targetSessionID, controllingProcessGroupID, controllingSessionID) {
    case (.failure(_), _, _, _),
         (_, .failure(_), _, _):
        return .unknown

    case (.success(let groupID), .success(let sessionID), .failure(_), _)
            where groupID == sessionID,
         (.success(let groupID), .success(let sessionID), _, .failure(_))
            where groupID == sessionID:
        return .backgroundLeader(groupID: groupID, sessionID: sessionID)

    case (.success(let groupID), .success(let sessionID), .failure(_), _),
         (.success(let groupID), .success(let sessionID), _, .failure(_)):
        return .backgroundFollower(groupID: groupID, sessionID: sessionID)

    case (.success(let target), .success(let sessionID), .success(let controlling), .success(_))
            where target == controlling:
        return .foregroundLeader(groupID: target, sessionID: sessionID)

    case (.success(let groupID), .success(let target), .success(_), .success(let controlling))
            where target == controlling:
        return .foregroundFollower(groupID: groupID, sessionID: target)

    case (.success(let groupID), .success(let sessionID), .success(_), .success(_))
            where groupID == sessionID:
        return .backgroundLeader(groupID: groupID, sessionID: sessionID)

    case (.success(let groupID), .success(let sessionID), .success(_), .success(_)):
        return .backgroundFollower(groupID: groupID, sessionID: sessionID)
    }
}

struct ExecutionSession {
    @TaskLocal private static var current: InteractivityState?

    static let metadataProvider = Logger.MetadataProvider {
        guard let current else { return [:] }
        return ["interactivity": current.metadata]
    }

    static func main(operation: () async throws -> Void) async throws {
        logger.trace("starting main execution session")

        let state = InteractivityState(pid: ProcessInfo.processInfo.processIdentifier)

        try $current.withValue(state) {
            try state.promote()
        }

        try await $current.withValue(state, operation: operation)
    }

    static func child(
        pid: Int32,
        operation: () async throws -> Void,
        onPromotionFailed: () async throws -> Void
    ) async throws {
        let parent = current!

        logger.trace("starting child execution session")

        let state = InteractivityState(pid: pid)

        try $current.withValue(state) {
            try state.promote()
            parent.refresh()
        }

        do {
            try await $current.withValue(state, operation: operation)
        } catch {
            parent.refresh()
            logger.error("child execution session failed", error: error)
            logger.trace("restoring previous leader")
            try parent.promote()
            throw error
        }

        parent.refresh()
        logger.trace("child execution session completed, restoring previous leader")
        try parent.promote()
    }
}
