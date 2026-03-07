import Foundation

/// GitHub Git Blobs API.
///
/// ```swift
/// // Get a blob (file content)
/// let blob = try await client.blobs.get(owner: "user", repo: "notes", sha: "abc123")
/// print(blob.decodedString ?? "binary data")
///
/// // Create a blob from text
/// let newBlob = try await client.blobs.create(owner: "user", repo: "notes", request: .utf8("# Hello"))
///
/// // Create a blob from binary data
/// let imageBlob = try await client.blobs.create(owner: "user", repo: "notes", request: .base64(imageData))
/// ```
public struct BlobsEndpoint: Sendable {
    let client: GitHubClient

    /// Get a blob by SHA.
    ///
    /// - Note: GitHub returns content base64-encoded. Use `blob.decodedData` or `blob.decodedString` for convenience.
    /// - Note: Blobs up to 100 MB are supported.
    public func get(owner: String, repo: String, sha: String) async throws -> GitBlob {
        try await client.request(path: "repos/\(owner)/\(repo)/git/blobs/\(sha)")
    }

    /// Create a new blob.
    ///
    /// - Returns: The created blob with its SHA (content is not echoed back).
    public func create(owner: String, repo: String, request: CreateBlobRequest) async throws -> GitBlob {
        try await client.request(method: "POST", path: "repos/\(owner)/\(repo)/git/blobs", body: request)
    }
}
