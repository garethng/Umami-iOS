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
}

struct UmamiEventPayload: Encodable, Sendable {
    let website: String
    let hostname: String
    let language: String?
    let screen: String?
    let url: String
    let referrer: String?
    let title: String?

    /// Umami commonly uses `event_type` as the event name field (keep compatibility).
    let eventType: String

    /// Umami commonly uses `event_value` as the event value field (string).
    let eventValue: String?

    /// Extra key-value payload (if your Umami instance / gateway allows pass-through).
    let data: [String: String]?

    enum CodingKeys: String, CodingKey {
        case website
        case hostname
        case language
        case screen
        case url
        case referrer
        case title
        case eventType = "event_type"
        case eventValue = "event_value"
        case data
    }
}


