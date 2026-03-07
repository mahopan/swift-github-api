#if canImport(AuthenticationServices)
import AuthenticationServices
import Foundation

/// Complete OAuth flow for Apple platforms using `ASWebAuthenticationSession`.
///
/// Handles the full flow: open browser → user authorizes → extract code → exchange for token.
///
/// ```swift
/// let config = OAuthConfiguration(
///     clientId: "Iv1.abc123",
///     clientSecret: "secret",
///     redirectURI: "mahonotes://github-callback",
///     scopes: ["repo"]
/// )
/// let flow = OAuthFlow(configuration: config)
///
/// // On iOS/macOS — presents the auth sheet
/// let token = try await flow.authenticate()
/// // token.accessToken → store in Keychain
/// ```
///
/// - Note: Only available on iOS 16+, macOS 13+, visionOS 1+.
@MainActor
public final class OAuthFlow {
    /// OAuth configuration.
    public let configuration: OAuthConfiguration

    /// Token exchange handler.
    private let exchange: OAuthTokenExchange

    public init(configuration: OAuthConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.exchange = OAuthTokenExchange(configuration: configuration, session: session)
    }

    /// Run the full OAuth flow: browser auth → code extraction → token exchange.
    ///
    /// - Returns: The token response containing the access token.
    /// - Throws: `OAuthError` if the user cancels, auth fails, or token exchange fails.
    public func authenticate() async throws -> OAuthTokenResponse {
        let state = generateState()

        let authURL = configuration.authorizationURL(state: state)
        let callbackScheme = extractScheme(from: configuration.redirectURI)

        let callbackURL = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<URL, Error>) in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackScheme
            ) { url, error in
                if let error = error as? ASWebAuthenticationSessionError,
                   error.code == .canceledLogin {
                    continuation.resume(throwing: OAuthError.cancelled)
                    return
                }
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let url else {
                    continuation.resume(throwing: OAuthError.invalidCallbackURL("nil"))
                    return
                }
                continuation.resume(returning: url)
            }

            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }

        let code = try exchange.extractCode(from: callbackURL, expectedState: state)
        return try await exchange.exchangeCode(code)
    }

    // MARK: - Helpers

    private func generateState() -> String {
        let bytes = (0..<32).map { _ in UInt8.random(in: 0...255) }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func extractScheme(from redirectURI: String) -> String? {
        guard let url = URL(string: redirectURI) else { return nil }
        return url.scheme
    }
}
#endif
