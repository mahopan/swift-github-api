import Foundation

/// GitHub Git References API.
///
/// ```swift
/// // Get the current HEAD of main
/// let ref = try await client.refs.get(owner: "user", repo: "notes", ref: "heads/main")
/// print(ref.object.sha)  // current commit SHA
///
/// // Update main to point to a new commit (fast-forward)
/// try await client.refs.update(owner: "user", repo: "notes", ref: "heads/main",
///     request: .init(sha: newCommitSha))
/// ```
public struct RefsEndpoint: Sendable {
    let client: GitHubClient

    /// Get a reference.
    ///
    /// - Parameter ref: The ref without `refs/` prefix (e.g., `"heads/main"`, `"tags/v1.0"`).
    public func get(owner: String, repo: String, ref: String) async throws -> GitRef {
        try await client.request(path: "repos/\(owner)/\(repo)/git/ref/\(ref)")
    }

    /// Update a reference to point to a new SHA.
    ///
    /// - Parameter ref: The ref without `refs/` prefix (e.g., `"heads/main"`).
    /// - Note: Use `force: true` in the request for non-fast-forward updates (not recommended for sync).
    public func update(owner: String, repo: String, ref: String, request: UpdateRefRequest) async throws -> GitRef {
        try await client.request(method: "PATCH", path: "repos/\(owner)/\(repo)/git/refs/\(ref)", body: request)
    }

    /// Create a new reference.
    ///
    /// - Parameter ref: Full ref name (e.g., `"refs/heads/new-branch"`).
    /// - Parameter sha: SHA to point to.
    public func create(owner: String, repo: String, ref: String, sha: String) async throws -> GitRef {
        struct CreateRefRequest: Encodable, Sendable {
            let ref: String
            let sha: String
        }
        return try await client.request(method: "POST", path: "repos/\(owner)/\(repo)/git/refs",
                                        body: CreateRefRequest(ref: ref, sha: sha))
    }
}
