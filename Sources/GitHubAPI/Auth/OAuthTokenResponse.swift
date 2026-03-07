import Foundation

/// Response from GitHub's OAuth token exchange endpoint.
public struct OAuthTokenResponse: Codable, Sendable {
    /// The access token.
    public let accessToken: String

    /// Token type (usually `"bearer"`).
    public let tokenType: String

    /// Granted scopes (comma-separated).
    public let scope: String

    /// Refresh token (only for GitHub Apps with expiring tokens).
    public let refreshToken: String?

    /// Seconds until the access token expires (only for expiring tokens).
    public let expiresIn: Int?

    /// Seconds until the refresh token expires.
    public let refreshTokenExpiresIn: Int?

    private enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case scope
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case refreshTokenExpiresIn = "refresh_token_expires_in"
    }

    /// The granted scopes as an array.
    public var scopeArray: [String] {
        scope.split(separator: ",").map { String($0) }
    }
}

/// Error response from the OAuth endpoint.
public struct OAuthErrorResponse: Codable, Sendable {
    public let error: String
    public let errorDescription: String?
    public let errorUri: String?

    private enum CodingKeys: String, CodingKey {
        case error
        case errorDescription = "error_description"
        case errorUri = "error_uri"
    }
}
