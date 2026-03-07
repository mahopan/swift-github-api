import Foundation

/// Handles the OAuth token exchange (code → access token).
///
/// This is platform-independent — works on macOS, iOS, iPadOS, and Linux.
///
/// ```swift
/// let config = OAuthConfiguration(clientId: "...", clientSecret: "...", redirectURI: "...")
/// let exchange = OAuthTokenExchange(configuration: config)
///
/// // After the user authorizes and you receive the callback URL:
/// let code = try exchange.extractCode(from: callbackURL, expectedState: "random-state")
/// let token = try await exchange.exchangeCode(code)
/// print(token.accessToken) // Store this in Keychain
/// ```
public struct OAuthTokenExchange: Sendable {
    /// OAuth configuration.
    public let configuration: OAuthConfiguration

    /// URLSession to use for the token exchange request.
    public let session: URLSession

    public init(configuration: OAuthConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    /// Extract the authorization code from a callback URL.
    ///
    /// - Parameters:
    ///   - callbackURL: The URL the browser redirected to after authorization.
    ///   - expectedState: The state parameter you sent in the authorization request (for CSRF validation).
    /// - Returns: The authorization code.
    /// - Throws: `OAuthError` if the URL is malformed, state doesn't match, or an error was returned.
    public func extractCode(from callbackURL: URL, expectedState: String) throws -> String {
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
            throw OAuthError.invalidCallbackURL(callbackURL.absoluteString)
        }

        let params = components.queryItems ?? []

        // Check for error response
        if let error = params.first(where: { $0.name == "error" })?.value {
            let description = params.first(where: { $0.name == "error_description" })?.value
            throw OAuthError.authorizationDenied(error: error, description: description)
        }

        // Validate state
        guard let state = params.first(where: { $0.name == "state" })?.value else {
            throw OAuthError.missingState
        }
        guard state == expectedState else {
            throw OAuthError.stateMismatch(expected: expectedState, received: state)
        }

        // Extract code
        guard let code = params.first(where: { $0.name == "code" })?.value else {
            throw OAuthError.missingCode
        }

        return code
    }

    /// Exchange an authorization code for an access token.
    ///
    /// - Parameter code: The authorization code from the callback URL.
    /// - Returns: The token response containing the access token.
    /// - Throws: `OAuthError` if the exchange fails.
    public func exchangeCode(_ code: String) async throws -> OAuthTokenResponse {
        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyParams = [
            "client_id=\(configuration.clientId)",
            "code=\(code)",
            "redirect_uri=\(configuration.redirectURI)",
        ]
        if let secret = configuration.clientSecret {
            bodyParams.append("client_secret=\(secret)")
        }
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            // Try to parse error response
            if let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                throw OAuthError.tokenExchangeFailed(
                    error: errorResponse.error,
                    description: errorResponse.errorDescription
                )
            }
            throw OAuthError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }

    /// Refresh an expiring access token using a refresh token.
    ///
    /// - Note: Only works with GitHub Apps that issue expiring tokens.
    /// - Parameter refreshToken: The refresh token from a previous token response.
    /// - Returns: A new token response.
    public func refreshToken(_ refreshToken: String) async throws -> OAuthTokenResponse {
        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyParams = [
            "client_id=\(configuration.clientId)",
            "grant_type=refresh_token",
            "refresh_token=\(refreshToken)",
        ]
        if let secret = configuration.clientSecret {
            bodyParams.append("client_secret=\(secret)")
        }
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                throw OAuthError.tokenExchangeFailed(
                    error: errorResponse.error,
                    description: errorResponse.errorDescription
                )
            }
            throw OAuthError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
    }
}
