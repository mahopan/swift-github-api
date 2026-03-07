import Foundation

/// Errors returned by the GitHub API client.
public enum GitHubError: Error, Sendable, CustomStringConvertible {
    /// HTTP 401 — invalid or expired token.
    case unauthorized

    /// HTTP 403 — insufficient permissions.
    case forbidden(message: String)

    /// HTTP 403 with rate limit headers — wait until `resetAt`.
    case rateLimited(resetAt: Date)

    /// HTTP 404 — resource not found.
    case notFound(message: String)

    /// HTTP 409 — conflict (e.g., non-fast-forward ref update).
    case conflict(message: String)

    /// HTTP 422 — validation error.
    case validationFailed(message: String)

    /// Other HTTP error.
    case httpError(statusCode: Int, message: String)

    /// Response was not an HTTP response.
    case invalidResponse

    public var description: String {
        switch self {
        case .unauthorized:
            return "GitHub API: unauthorized (401). Check your token."
        case .forbidden(let message):
            return "GitHub API: forbidden (403). \(message)"
        case .rateLimited(let resetAt):
            let formatter = DateFormatter()
            formatter.dateStyle = .none
            formatter.timeStyle = .medium
            return "GitHub API: rate limited. Resets at \(formatter.string(from: resetAt))."
        case .notFound(let message):
            return "GitHub API: not found (404). \(message)"
        case .conflict(let message):
            return "GitHub API: conflict (409). \(message)"
        case .validationFailed(let message):
            return "GitHub API: validation failed (422). \(message)"
        case .httpError(let statusCode, let message):
            return "GitHub API: HTTP \(statusCode). \(message)"
        case .invalidResponse:
            return "GitHub API: invalid response (not HTTP)."
        }
    }
}
