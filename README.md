# umami-ios

A lightweight Swift Package for iOS that sends tracking data to Umami via HTTP (`/api/send`) for `pageview` and `event`.

## Installation

Add this repository to your app’s **Package Dependencies**, then `import umami_ios`.

## Usage

```swift
import umami_ios

let client = UmamiClient(
    configuration: UmamiConfiguration(
        serverURL: URL(string: "https://analytics.example.com")!,
        websiteID: "YOUR_WEBSITE_ID",
        // Optional: closer to Umami web semantics
        hostName: Bundle.main.bundleIdentifier ?? "ios"
    )
)

// 1) Track a page view (use a stable “virtual URL” to represent your screen/route)
Task {
    try await client.trackPageView(
        url: "app://home",
        title: "Home"
    )
}

// 2) Track a custom event
Task {
    try await client.trackEvent(
        name: "signup",
        value: "1",
        url: "app://signup",
        data: ["plan": "pro"]
    )
}
```

## Notes

- `url`: iOS doesn’t have a browser address bar. It’s recommended to use your own scheme (e.g. `app://`) to map screens/routes to Umami consistently.
- `hostName`: defaults to the bundle id (you can change it to app name, channel, etc. if needed).
- Logging: silent by default. To integrate with your own logging system, implement `UmamiLogging` and inject it when creating `UmamiClient`.


