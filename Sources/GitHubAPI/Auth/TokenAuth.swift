import Foundation

/// Simple token-based authentication (PAT or OAuth access token).
///
/// ```swift
/// let client = GitHubClient(auth: TokenAuth(token: "ghp_..."))
/// ```
public struct TokenAuth: AuthProvider, Sendable {
    private let _token: String

    public init(token: String) {
        self._token = token
    }

    public func token() async throws -> String {
        _token
    }
}
