# umami-ios

A lightweight Swift Package for iOS that sends tracking data to Umami via HTTP (`/api/send`) for `pageview` and `event`.

## Installation

### Swift Package Manager (SPM)

#### Xcode

- In Xcode: **File → Add Package Dependencies…**
- Paste the repository URL
- Add the product **`umami-ios`** to your app target
- Then `import umami_ios`

#### Package.swift

Add the dependency and product to your `Package.swift`:

```swift
// Package.swift
dependencies: [
    // If you haven't published a semver tag yet, depend on the main branch:
    .package(url: "https://github.com/garethng/Umami-iOS.git", branch: "main"),
    //
    // Or, once you publish tags (recommended), use:
    // .package(url: "https://github.com/garethng/Umami-iOS.git", from: "0.1.0"),
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [
            .product(name: "umami-ios", package: "umami-ios"),
        ]
    ),
]
```

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
- `userID`: defaults to a UUID stored in `UserDefaults` (key: `umami_ios.user_id`). It is sent as `payload.id` on every request. You can override it via `UmamiConfiguration(userID:)`.
- `userAgent`: by default we do not override the header (use the system networking stack User-Agent). You can override it via `UmamiConfiguration(userAgent:)` if your setup requires.
- Events: `trackEvent` sends `payload.name` and `payload.data` to align with Umami’s `/api/send` API. The `value` parameter is merged into `data["value"]` for convenience.
- Logging: silent by default. To integrate with your own logging system, implement `UmamiLogging` and inject it when creating `UmamiClient`.


