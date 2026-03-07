import Foundation

/// Protocol for providing authentication tokens to the GitHub client.
///
/// Implement this protocol for custom auth flows (e.g., Keychain, OAuth refresh).
public protocol AuthProvider: Sendable {
    /// Return a valid token string for the `Authorization: Bearer <token>` header.
    func token() async throws -> String
}
