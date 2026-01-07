import Foundation

/// Lightweight logging interface (silent by default).
///
/// You can inject your own implementation to bridge logs into your logging stack
/// (e.g. OSLog, CocoaLumberjack, etc.).
public protocol UmamiLogging: Sendable {
    func log(_ message: String)
}

public struct UmamiNoopLogger: UmamiLogging {
    public init() {}
    public func log(_ message: String) {}
}


