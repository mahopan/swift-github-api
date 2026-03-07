import Foundation

/// Configuration for GitHub OAuth flow.
///
/// Create a GitHub OAuth App at https://github.com/settings/developers to get
/// your client ID and client secret.
///
/// ```swift
/// let config = OAuthConfiguration(
///     clientId: "Iv1.abc123",
///     clientSecret: "secret", // optional for public native apps
///     redirectURI: "mahonotes://github-callback",
///     scopes: ["repo"]
/// )
/// ```
public struct OAuthConfiguration: Sendable {
    /// GitHub OAuth client ID.
    public let clientId: String

    /// GitHub OAuth client secret. Optional for public native apps using PKCE,
    /// but required for standard OAuth flow.
    public let clientSecret: String?

    /// Redirect URI registered with the GitHub OAuth App.
    /// For native apps, use a custom URL scheme (e.g., `"mahonotes://github-callback"`).
    public let redirectURI: String

    /// OAuth scopes to request. Common scopes:
    /// - `"repo"` — full access to private repos
    /// - `"public_repo"` — access to public repos only
    public let scopes: [String]

    /// Base URL for GitHub OAuth (default: `https://github.com`).
    /// Change for GitHub Enterprise.
    public let baseURL: URL

    public init(
        clientId: String,
        clientSecret: String? = nil,
        redirectURI: String,
        scopes: [String] = ["repo"],
        baseURL: URL = URL(string: "https://github.com")!
    ) {
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.baseURL = baseURL
    }

    /// The authorization URL to present to the user.
    ///
    /// - Parameter state: Random string for CSRF protection (caller generates).
    /// - Returns: The full authorization URL.
    public func authorizationURL(state: String) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent("login/oauth/authorize"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
        ]
        return components.url!
    }

    /// The token exchange URL.
    internal var tokenURL: URL {
        baseURL.appendingPathComponent("login/oauth/access_token")
    }
}
