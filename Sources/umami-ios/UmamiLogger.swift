import Foundation

/// 轻量日志接口（默认静默）。你可以注入实现把日志接到你自己的 logger（例如 OSLog、CocoaLumberjack 等）。
public protocol UmamiLogging: Sendable {
    func log(_ message: String)
}

public struct UmamiNoopLogger: UmamiLogging {
    public init() {}
    public func log(_ message: String) {}
}


