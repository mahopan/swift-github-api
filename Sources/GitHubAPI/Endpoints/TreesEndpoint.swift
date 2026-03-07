import Foundation

/// GitHub Git Trees API.
///
/// ```swift
/// // Get a tree recursively (all files in the repo)
/// let tree = try await client.trees.get(owner: "user", repo: "notes", sha: "HEAD", recursive: true)
///
/// // Create a new tree based on an existing one
/// let newTree = try await client.trees.create(owner: "user", repo: "notes", request: .init(
///     baseTree: tree.sha,
///     tree: [.inlineBlob(path: "hello.md", content: "# Hello")]
/// ))
/// ```
public struct TreesEndpoint: Sendable {
    let client: GitHubClient

    /// Get a tree by SHA.
    ///
    /// - Parameters:
    ///   - owner: Repository owner.
    ///   - repo: Repository name.
    ///   - sha: Tree SHA, branch name, or `"HEAD"`.
    ///   - recursive: If `true`, returns all nested entries (flattened). Default `false`.
    /// - Returns: The tree object with its entries.
    public func get(owner: String, repo: String, sha: String, recursive: Bool = false) async throws -> GitTree {
        var query: [String: String]? = nil
        if recursive {
            query = ["recursive": "1"]
        }
        return try await client.request(path: "repos/\(owner)/\(repo)/git/trees/\(sha)", query: query)
    }

    /// Create a new tree.
    ///
    /// - Parameters:
    ///   - owner: Repository owner.
    ///   - repo: Repository name.
    ///   - request: The tree entries to create.
    /// - Returns: The created tree object.
    public func create(owner: String, repo: String, request: CreateTreeRequest) async throws -> GitTree {
        try await client.request(method: "POST", path: "repos/\(owner)/\(repo)/git/trees", body: request)
    }
}
