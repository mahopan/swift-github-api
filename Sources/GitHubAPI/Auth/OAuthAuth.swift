import Foundation

/// Auth provider that uses an OAuth access token with optional auto-refresh.
///
/// ```swift
/// // Simple (no refresh)
/// let auth = OAuthAuth(accessToken: "gho_...")
///
/// // With refresh
/// let auth = OAuthAuth(
///     accessToken: "gho_...",
///     refreshToken: "ghr_...",
///     expiresAt: Date().addingTimeInterval(3600),
///     configuration: oauthConfig,
///     onTokenRefresh: { newToken in
///         // Store newToken.accessToken in Keychain
///     }
/// )
/// let client = GitHubClient(auth: auth)
/// ```
public final class OAuthAuth: AuthProvider, @unchecked Sendable {
    private var _accessToken: String
    private var _refreshToken: String?
    private var _expiresAt: Date?
    private let _configuration: OAuthConfiguration?
    private let _onTokenRefresh: (@Sendable (OAuthTokenResponse) async -> Void)?
    private let _session: URLSession
    private let _lock = NSLock()

    /// Create an OAuth auth provider.
    ///
    /// - Parameters:
    ///   - accessToken: The current access token.
    ///   - refreshToken: Optional refresh token for auto-refresh.
    ///   - expiresAt: When the access token expires. If nil, token is assumed non-expiring.
    ///   - configuration: OAuth config needed for refresh. Required if refresh token is provided.
    ///   - session: URLSession for refresh requests.
    ///   - onTokenRefresh: Callback when a token is refreshed (e.g., to update Keychain).
    public init(
        accessToken: String,
        refreshToken: String? = nil,
        expiresAt: Date? = nil,
        configuration: OAuthConfiguration? = nil,
        session: URLSession = .shared,
        onTokenRefresh: (@Sendable (OAuthTokenResponse) async -> Void)? = nil
    ) {
        self._accessToken = accessToken
        self._refreshToken = refreshToken
        self._expiresAt = expiresAt
        self._configuration = configuration
        self._session = session
        self._onTokenRefresh = onTokenRefresh
    }

    public func token() async throws -> String {
        // Check if token needs refresh
        if let expiresAt = _lock.withLock({ _expiresAt }),
           let refreshToken = _lock.withLock({ _refreshToken }),
           let config = _configuration {
            // Refresh if expiring within 5 minutes
            if expiresAt.timeIntervalSinceNow < 300 {
                let exchange = OAuthTokenExchange(configuration: config, session: _session)
                let response = try await exchange.refreshToken(refreshToken)

                _lock.withLock {
                    _accessToken = response.accessToken
                    _refreshToken = response.refreshToken ?? refreshToken
                    if let expiresIn = response.expiresIn {
                        _expiresAt = Date().addingTimeInterval(Double(expiresIn))
                    }
                }

                await _onTokenRefresh?(response)
            }
        }

        return _lock.withLock { _accessToken }
    }
}
