import Foundation

public enum UmamiError: Error, Sendable, Equatable {
    case invalidSendURL
    case invalidResponse
    case badStatusCode(Int)
}


