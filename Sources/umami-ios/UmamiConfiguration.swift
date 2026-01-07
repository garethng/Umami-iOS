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

    /// Persistent user identifier (UUID string).
    ///
    /// Defaults to a UUID stored in `UserDefaults` (generated once and reused).
    /// This value is sent as `payload.id` on every request.
    public var userID: String

    /// Optional `User-Agent` header.
    ///
    /// If `nil`, we do not override the header and let the system networking stack
    /// provide the device's default User-Agent.
    public var userAgent: String?

    /// Extra static headers (e.g. required by your gateway).
    public var additionalHeaders: [String: String]

    public init(
        serverURL: URL,
        websiteID: String,
        sendPath: String = "/api/send",
        hostName: String = (Bundle.main.bundleIdentifier ?? "ios"),
        language: String? = Locale.preferredLanguages.first,
        userID: String = UmamiUserIdentifier.getOrCreate(),
        userAgent: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) {
        self.serverURL = serverURL
        self.websiteID = websiteID
        self.sendPath = sendPath
        self.hostName = hostName
        self.language = language
        self.userID = userID
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
        // By default, do not override User-Agent: use system networking stack UA.
        nil
    }
}


