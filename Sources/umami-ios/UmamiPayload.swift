import Foundation

enum UmamiSendType: String, Encodable {
    case pageview
    case event
}

struct UmamiSendRequest<Payload: Encodable>: Encodable {
    let type: UmamiSendType
    let payload: Payload
}

/// Common fields typically used by Umami's tracker payload.
///
/// On iOS, some fields need to be provided by the caller.
struct UmamiBasePayload: Encodable, Sendable {
    let website: String
    let hostname: String
    let language: String?
    let screen: String?
    let url: String
    let referrer: String?
    let title: String?
    /// Additional tag description (optional).
    let tag: String?
    /// Session identifier (optional).
    let id: String?
    /// Extra key-value payload (some Umami setups accept this for pageviews too).
    let data: [String: String]?
}

struct UmamiEventPayload: Encodable, Sendable {
    let website: String
    let hostname: String
    let language: String?
    let screen: String?
    let url: String
    let referrer: String?
    let title: String?

    /// Name of the event.
    let name: String

    /// Extra key-value payload (official `/api/send` supports an object here).
    let data: [String: String]?

    /// Additional tag description (optional).
    let tag: String?

    /// Session identifier (optional).
    let id: String?
}


