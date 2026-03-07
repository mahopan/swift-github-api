import Foundation

/// Errors from the OAuth flow.
public enum OAuthError: Error, Sendable, CustomStringConvertible {
    /// The callback URL couldn't be parsed.
    case invalidCallbackURL(String)

    /// The state parameter was missing from the callback.
    case missingState

    /// The state parameter didn't match (possible CSRF).
    case stateMismatch(expected: String, received: String)

    /// The authorization code was missing from the callback.
    case missingCode

    /// The user denied authorization, or another OAuth error occurred.
    case authorizationDenied(error: String, description: String?)

    /// Token exchange failed.
    case tokenExchangeFailed(error: String, description: String?)

    /// HTTP error during token exchange.
    case httpError(statusCode: Int)

    /// Response was not HTTP.
    case invalidResponse

    /// The presentation context (window) couldn't be found.
    case noPresentationAnchor

    /// ASWebAuthenticationSession was cancelled by the user.
    case cancelled

    public var description: String {
        switch self {
        case .invalidCallbackURL(let url):
            return "OAuth: invalid callback URL: \(url)"
        case .missingState:
            return "OAuth: state parameter missing from callback (possible CSRF)"
        case .stateMismatch(let expected, let received):
            return "OAuth: state mismatch — expected '\(expected)', got '\(received)'"
        case .missingCode:
            return "OAuth: authorization code missing from callback"
        case .authorizationDenied(let error, let description):
            return "OAuth: \(error)\(description.map { " — \($0)" } ?? "")"
        case .tokenExchangeFailed(let error, let description):
            return "OAuth: token exchange failed — \(error)\(description.map { ": \($0)" } ?? "")"
        case .httpError(let statusCode):
            return "OAuth: HTTP error \(statusCode)"
        case .invalidResponse:
            return "OAuth: invalid response (not HTTP)"
        case .noPresentationAnchor:
            return "OAuth: no presentation anchor (window) available"
        case .cancelled:
            return "OAuth: cancelled by user"
        }
    }
}
