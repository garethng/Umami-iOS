import Foundation

enum UmamiSendType: String, Encodable {
    case pageview
    case event
}

struct UmamiSendRequest<Payload: Encodable>: Encodable {
    let type: UmamiSendType
    let payload: Payload
}

/// 对齐 Umami tracker 的常见字段集合（iOS 侧部分字段由调用方提供）。
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

    /// Umami 里事件类型字段通常用 `event_type`（保持兼容）。
    let eventType: String

    /// Umami 里事件值字段通常用 `event_value`（字符串）。
    let eventValue: String?

    /// 额外自定义字段（如果你的 Umami/网关允许透传）。
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


