import Foundation

/// Configuration for GitHub Device Flow (OAuth 2.0 Device Authorization Grant).
///
/// Device Flow doesn't require a client secret, making it safe for native apps
/// distributed via App Store.
///
/// ```swift
/// let config = DeviceFlowConfiguration(
///     clientId: "Iv1.abc123",
///     scopes: ["repo"]
/// )
/// ```
///
/// - Note: You must enable Device Flow in your GitHub OAuth App settings.
public struct DeviceFlowConfiguration: Sendable {
    /// GitHub OAuth client ID.
    public let clientId: String

    /// OAuth scopes to request.
    public let scopes: [String]

    /// Base URL for GitHub (default: `https://github.com`).
    /// Change for GitHub Enterprise.
    public let baseURL: URL

    public init(
        clientId: String,
        scopes: [String] = ["repo"],
        baseURL: URL = URL(string: "https://github.com")!
    ) {
        self.clientId = clientId
        self.scopes = scopes
        self.baseURL = baseURL
    }

    /// The device code request URL.
    internal var deviceCodeURL: URL {
        baseURL.appendingPathComponent("login/device/code")
    }

    /// The token exchange URL.
    internal var tokenURL: URL {
        baseURL.appendingPathComponent("login/oauth/access_token")
    }
}
