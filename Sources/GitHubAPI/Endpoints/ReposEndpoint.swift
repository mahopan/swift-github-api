import Foundation

/// GitHub Repositories API (minimal — just what's needed for sync).
///
/// ```swift
/// let repo = try await client.repos.get(owner: "user", repo: "notes")
/// let canPush = repo.permissions?.push ?? false
/// ```
public struct ReposEndpoint: Sendable {
    let client: GitHubClient

    /// Get repository metadata.
    ///
    /// Includes `permissions` when authenticated — use to check push access.
    public func get(owner: String, repo: String) async throws -> Repository {
        try await client.request(path: "repos/\(owner)/\(repo)")
    }
}
