import Testing
import Foundation
@testable import umami_ios

final class Locked<Value>: @unchecked Sendable {
    private var value: Value
    private let lock = NSLock()

    init(_ value: Value) {
        self.value = value
    }

    func withValue<R>(_ body: (inout Value) throws -> R) rethrows -> R {
        lock.lock()
        defer { lock.unlock() }
        return try body(&value)
    }
}

final class MockURLProtocol: URLProtocol {
    static let handlersByID = Locked<[String: (URLRequest) throws -> (HTTPURLResponse, Data)]>([:])
    static let routingHeader = "X-UmamiIOS-Test-ID"

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard
            let id = headerValue(request, Self.routingHeader),
            let handler = Self.handlersByID.withValue({ $0[id] })
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let normalized = Self.normalizedRequest(request)
            let (resp, data) = try handler(normalized)
            client?.urlProtocol(self, didReceive: resp, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

extension MockURLProtocol {
    /// URLSession 可能把 body 放在 `httpBodyStream` 里；这里统一成 `httpBody` 方便测试断言。
    static func normalizedRequest(_ request: URLRequest) -> URLRequest {
        var req = request
        if req.httpBody == nil, let stream = req.httpBodyStream {
            req.httpBody = readAll(from: stream)
        }
        return req
    }

    static func readAll(from stream: InputStream) -> Data {
        stream.open()
        defer { stream.close() }

        var data = Data()
        let bufferSize = 16 * 1024
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while stream.hasBytesAvailable {
            let read = stream.read(&buffer, maxLength: bufferSize)
            if read > 0 {
                data.append(buffer, count: read)
            } else {
                break
            }
        }
        return data
    }
}

private func headerValue(_ request: URLRequest, _ name: String) -> String? {
    if let v = request.value(forHTTPHeaderField: name) { return v }
    guard let all = request.allHTTPHeaderFields else { return nil }
    let key = all.keys.first { $0.caseInsensitiveCompare(name) == .orderedSame }
    return key.flatMap { all[$0] }
}

private func makeSession() -> URLSession {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [MockURLProtocol.self]
    return URLSession(configuration: config)
}

@Test func trackPageView_buildsExpectedRequest() async throws {
    let serverURL = try #require(URL(string: "https://analytics.example.com"))
    let testID = UUID().uuidString
    let session = makeSession()
    let client = UmamiClient(
        configuration: UmamiConfiguration(
            serverURL: serverURL,
            websiteID: "website-123",
            hostName: "com.example.app",
            language: "zh-CN",
            userAgent: "TestUA/1.0",
            additionalHeaders: ["X-Test": "1", MockURLProtocol.routingHeader: testID]
        ),
        session: session
    )

    MockURLProtocol.handlersByID.withValue { $0[testID] = { req in
        #expect(req.httpMethod == "POST")
        #expect(req.url?.absoluteString == "https://analytics.example.com/api/send")
        #expect(headerValue(req, "Content-Type") == "application/json")
        #expect(headerValue(req, "User-Agent") == "TestUA/1.0")
        #expect(headerValue(req, "X-Test") == "1")

        let body = try #require(req.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let type = json?["type"] as? String
        let payload = json?["payload"] as? [String: Any]

        #expect(type == "pageview")
        #expect(payload?["website"] as? String == "website-123")
        #expect(payload?["hostname"] as? String == "com.example.app")
        #expect(payload?["language"] as? String == "zh-CN")
        #expect(payload?["url"] as? String == "app://home")
        #expect(payload?["title"] as? String == "Home")
        #expect(payload?["referrer"] as? String == "app://launch")

        let resp = HTTPURLResponse(url: req.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!
        return (resp, Data())
    } }

    try await client.trackPageView(url: "app://home", title: "Home", referrer: "app://launch")
}

@Test func trackEvent_buildsExpectedRequest() async throws {
    let serverURL = try #require(URL(string: "https://analytics.example.com"))
    let testID = UUID().uuidString
    let session = makeSession()
    let client = UmamiClient(
        configuration: UmamiConfiguration(
            serverURL: serverURL,
            websiteID: "website-123",
            hostName: "com.example.app",
            language: "en-US",
            userAgent: nil,
            additionalHeaders: [MockURLProtocol.routingHeader: testID]
        ),
        session: session
    )

    MockURLProtocol.handlersByID.withValue { $0[testID] = { req in
        let body = try #require(req.httpBody)
        let json = try JSONSerialization.jsonObject(with: body) as? [String: Any]
        let type = json?["type"] as? String
        let payload = json?["payload"] as? [String: Any]

        #expect(type == "event")
        #expect(payload?["website"] as? String == "website-123")
        #expect(payload?["event_type"] as? String == "signup")
        #expect(payload?["event_value"] as? String == "1")
        #expect(payload?["url"] as? String == "app://signup")
        #expect((payload?["data"] as? [String: Any])?["plan"] as? String == "pro")

        let resp = HTTPURLResponse(url: req.url!, statusCode: 204, httpVersion: nil, headerFields: nil)!
        return (resp, Data())
    } }

    try await client.trackEvent(
        name: "signup",
        value: "1",
        url: "app://signup",
        data: ["plan": "pro"]
    )
}
