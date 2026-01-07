import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Umami 上报客户端（面向 iOS）。
public actor UmamiClient {
    private let config: UmamiConfiguration
    private let session: URLSession
    private let logger: UmamiLogging

    public init(
        configuration: UmamiConfiguration,
        session: URLSession = .shared,
        logger: UmamiLogging = UmamiNoopLogger()
    ) {
        self.config = configuration
        self.session = session
        self.logger = logger
    }

    /// 上报一次页面访问（pageview）。
    ///
    /// - Parameters:
    ///   - url: 建议使用你自己定义的“虚拟 URL”（例如 `app://home`、`app://settings/profile`），用于在 Umami 里区分页面/路由。
    ///   - title: 页面标题/屏幕名称。
    ///   - referrer: 来源（可选）。
    public func trackPageView(
        url: String,
        title: String? = nil,
        referrer: String? = nil
    ) async throws {
        let payload = UmamiBasePayload(
            website: config.websiteID,
            hostname: config.hostName,
            language: config.language,
            screen: Self.screenString(),
            url: url,
            referrer: referrer,
            title: title
        )

        let req = UmamiSendRequest(type: .pageview, payload: payload)
        try await send(req)
    }

    /// 上报一次自定义事件（event）。
    ///
    /// - Parameters:
    ///   - name: 事件名（映射到 Umami 的 `event_type`）。
    ///   - value: 事件值（映射到 Umami 的 `event_value`，可选）。
    ///   - url: 事件关联的页面/路由（同 pageview 的 url 语义）。
    ///   - title: 事件关联的页面标题/屏幕名称（可选）。
    ///   - referrer: 来源（可选）。
    ///   - data: 额外 key-value（如果你的 Umami/网关接受透传）。
    public func trackEvent(
        name: String,
        value: String? = nil,
        url: String,
        title: String? = nil,
        referrer: String? = nil,
        data: [String: String]? = nil
    ) async throws {
        let payload = UmamiEventPayload(
            website: config.websiteID,
            hostname: config.hostName,
            language: config.language,
            screen: Self.screenString(),
            url: url,
            referrer: referrer,
            title: title,
            eventType: name,
            eventValue: value,
            data: data
        )

        let req = UmamiSendRequest(type: .event, payload: payload)
        try await send(req)
    }

    private func send<Payload: Encodable>(_ body: UmamiSendRequest<Payload>) async throws {
        guard let url = Self.makeSendURL(serverURL: config.serverURL, sendPath: config.sendPath) else {
            throw UmamiError.invalidSendURL
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let ua = config.userAgent, !ua.isEmpty {
            req.setValue(ua, forHTTPHeaderField: "User-Agent")
        }

        for (k, v) in config.additionalHeaders {
            req.setValue(v, forHTTPHeaderField: k)
        }

        let encoder = JSONEncoder()
        req.httpBody = try encoder.encode(body)

        let (_, resp) = try await session.dataCompat(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw UmamiError.invalidResponse
        }

        guard (200...299).contains(http.statusCode) else {
            logger.log("Umami send failed with statusCode=\(http.statusCode)")
            throw UmamiError.badStatusCode(http.statusCode)
        }
    }
}

extension UmamiClient {
    nonisolated static func screenString() -> String? {
        #if canImport(UIKit)
        let bounds = UIScreen.main.bounds
        let scale = UIScreen.main.scale
        let w = Int(bounds.size.width * scale)
        let h = Int(bounds.size.height * scale)
        return "\(w)x\(h)"
        #else
        return nil
        #endif
    }
}

extension UmamiClient {
    nonisolated static func makeSendURL(serverURL: URL, sendPath: String) -> URL? {
        guard var comps = URLComponents(url: serverURL, resolvingAgainstBaseURL: false) else { return nil }
        let basePath = (comps.path == "/") ? "" : comps.path
        let normalized = "/" + sendPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        comps.path = basePath + normalized
        return comps.url
    }
}

extension URLSession {
    /// iOS 13 / macOS 11 兼容的 async 包装（避免 `URLSession.data(for:)` 的可用性限制）。
    func dataCompat(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = dataTask(with: request) { data, response, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let data, let response else {
                    continuation.resume(throwing: URLError(.badServerResponse))
                    return
                }
                continuation.resume(returning: (data, response))
            }
            task.resume()
        }
    }
}


