import Foundation

/// Umami 上报配置。
public struct UmamiConfiguration: Sendable, Equatable {
    /// 例如：`https://analytics.example.com`
    public var serverURL: URL

    /// Umami Website ID（UUID 字符串）。
    public var websiteID: String

    /// 上报 endpoint 路径。默认是 Umami tracker 常用的 `/api/send`。
    public var sendPath: String

    /// 对应 Umami payload 里的 `hostname`。
    ///
    /// Web 端通常是 `location.hostname`；iOS 场景建议用 bundle id 或你的 app 名。
    public var hostName: String

    /// 对应 Umami payload 里的 `language`。
    public var language: String?

    /// 是否携带 `User-Agent` 头（部分反向代理/防火墙可能依赖它）。
    public var userAgent: String?

    /// 额外固定请求头（比如你自建网关需要的 header）。
    public var additionalHeaders: [String: String]

    public init(
        serverURL: URL,
        websiteID: String,
        sendPath: String = "/api/send",
        hostName: String = UmamiConfiguration.defaultHostName,
        language: String? = UmamiConfiguration.defaultLanguage,
        userAgent: String? = UmamiConfiguration.defaultUserAgent,
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
        // 轻量 UA：有就带，没有也不强依赖
        let bundle = Bundle.main
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? "App"
        let version = (bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "0"
        let build = (bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String) ?? "0"
        return "\(name)/\(version) (\(build))"
    }
}


