import Foundation

/// Umami tracking configuration.
public struct UmamiConfiguration: Sendable, Equatable {
    /// Example: `https://analytics.example.com`
    public var serverURL: URL

    /// Umami Website ID (UUID string).
    public var websiteID: String

    /// Send endpoint path. Defaults to `/api/send` (commonly used by Umami's tracker).
    public var sendPath: String

    /// Maps to `hostname` in Umami's payload.
    ///
    /// On the web, this is typically `location.hostname`.
    /// On iOS, it's recommended to use your bundle id or app name.
    public var hostName: String

    /// Maps to `language` in Umami's payload.
    public var language: String?

    /// Whether to send a `User-Agent` header (some proxies / firewalls may rely on it).
    public var userAgent: String?

    /// Extra static headers (e.g. required by your gateway).
    public var additionalHeaders: [String: String]

    public init(
        serverURL: URL,
        websiteID: String,
        sendPath: String = "/api/send",
        hostName: String = (Bundle.main.bundleIdentifier ?? "ios"),
        language: String? = Locale.preferredLanguages.first,
        userAgent: String? = {
            let bundle = Bundle.main
            let name = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "App"
            let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
            let build = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "0"
            return "\(name)/\(version) (\(build))"
        }(),
        additionalHeaders: [String: String] = [:]
    ) {
        self.serverURL = serverURL
        self.websiteID = websiteID
        self.sendPath = sendPath
        self.hostName = hostName
        self.language = language
        self.userAgent = userAgent
        self.additionalHeaders = additionalHeaders
    }
}

extension UmamiConfiguration {
    public static var defaultHostName: String {
        Bundle.main.bundleIdentifier ?? "ios"
    }

    public static var defaultLanguage: String? {
        Locale.preferredLanguages.first
    }

    public static var defaultUserAgent: String? {
        // Lightweight UA: optional, not required by default.
        let bundle = Bundle.main
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "App"
        let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
        let build = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "0"
        return "\(name)/\(version) (\(build))"
    }
}


