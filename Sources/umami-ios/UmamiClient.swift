import Foundation

#if canImport(UIKit)
import UIKit
#endif

/// Umami tracking client (for iOS).
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

    /// Track a page view.
    ///
    /// - Parameters:
    ///   - url: Use a stable “virtual URL” to represent your screen/route
    ///          (e.g. `app://home`, `app://settings/profile`).
    ///   - title: Screen title / name.
    ///   - referrer: Optional referrer.
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
            title: title,
            tag: nil,
            id: config.userID,
            data: nil
        )

        let req = UmamiSendRequest(type: .pageview, payload: payload)
        try await send(req)
    }

    /// Track a custom event.
    ///
    /// - Parameters:
    ///   - name: Event name (mapped to Umami `payload.name`).
    ///   - value: Convenience value (merged into `payload.data["value"]` if provided).
    ///   - url: Screen/route associated with the event (same semantics as pageview's `url`).
    ///   - title: Screen title / name (optional).
    ///   - referrer: Optional referrer.
    ///   - tag: Optional tag description.
    ///   - data: Extra key-value data (sent as `payload.data`).
    public func trackEvent(
        name: String,
        value: String? = nil,
        url: String,
        title: String? = nil,
        referrer: String? = nil,
        tag: String? = nil,
        data: [String: String]? = nil
    ) async throws {
        var mergedData = data ?? [:]
        if let value {
            mergedData["value"] = value
        }

        let payload = UmamiEventPayload(
            website: config.websiteID,
            hostname: config.hostName,
            language: config.language,
            screen: Self.screenString(),
            url: url,
            referrer: referrer,
            title: title,
            name: name,
            data: mergedData.isEmpty ? nil : mergedData,
            tag: tag,
            id: config.userID
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
    /// iOS 13 / macOS 11 compatible async wrapper (avoids availability constraints of `URLSession.data(for:)`).
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


