import Foundation

/// GitHub Git Commits API.
///
/// ```swift
/// // Get a commit
/// let commit = try await client.commits.get(owner: "user", repo: "notes", sha: "abc123")
///
/// // Create a commit
/// let newCommit = try await client.commits.create(owner: "user", repo: "notes", request: .init(
///     message: "sync: update notes",
///     tree: newTreeSha,
///     parents: [currentCommitSha]
/// ))
/// ```
public struct CommitsEndpoint: Sendable {
    let client: GitHubClient

    /// Get a commit by SHA.
    public func get(owner: String, repo: String, sha: String) async throws -> GitCommit {
        try await client.request(path: "repos/\(owner)/\(repo)/git/commits/\(sha)")
    }

    /// Create a new commit.
    ///
    /// - Returns: The created commit object.
    public func create(owner: String, repo: String, request: CreateCommitRequest) async throws -> GitCommit {
        try await client.request(method: "POST", path: "repos/\(owner)/\(repo)/git/commits", body: request)
    }
}
