import Foundation

/// GitHub Repository Contents API (convenience for downloading individual files).
///
/// For bulk operations, prefer the Trees + Blobs API which is more efficient.
///
/// ```swift
/// let file = try await client.contents.get(owner: "user", repo: "notes", path: "README.md")
/// print(file.decodedString ?? "")
/// ```
public struct ContentsEndpoint: Sendable {
    let client: GitHubClient

    /// Get the contents of a file.
    ///
    /// - Parameter ref: Branch, tag, or commit SHA. Default: repo's default branch.
    public func get(owner: String, repo: String, path: String, ref: String? = nil) async throws -> FileContent {
        var query: [String: String]? = nil
        if let ref {
            query = ["ref": ref]
        }
        return try await client.request(path: "repos/\(owner)/\(repo)/contents/\(path)", query: query)
    }
}

/// A file from the Contents API.
public struct FileContent: Codable, Sendable {
    public let name: String
    public let path: String
    public let sha: String
    public let size: Int
    public let content: String?
    public let encoding: String?
    public let type: String  // "file", "dir", "symlink", "submodule"

    /// Decode the base64 content to Data.
    public var decodedData: Data? {
        guard let content, encoding == "base64" else { return nil }
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        return Data(base64Encoded: cleaned)
    }

    /// Decode the base64 content to a UTF-8 string.
    public var decodedString: String? {
        guard let data = decodedData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
