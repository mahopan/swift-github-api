import Foundation

/// A Git tree object from the GitHub API.
public struct GitTree: Codable, Sendable {
    /// SHA of this tree.
    public let sha: String

    /// The tree entries (files and subdirectories).
    public let tree: [TreeEntry]

    /// Whether the tree was truncated (too many entries for a single response).
    public let truncated: Bool?

    public init(sha: String, tree: [TreeEntry], truncated: Bool? = nil) {
        self.sha = sha
        self.tree = tree
        self.truncated = truncated
    }
}

/// A single entry in a Git tree.
public struct TreeEntry: Codable, Sendable {
    /// File path (relative to tree root).
    public let path: String

    /// File mode (`"100644"` = normal file, `"100755"` = executable, `"040000"` = directory, `"120000"` = symlink, `"160000"` = submodule).
    public let mode: String

    /// Object type: `"blob"`, `"tree"`, or `"commit"`.
    public let type: String

    /// SHA of the object.
    public let sha: String?

    /// Size in bytes (only for blobs, nil for trees).
    public let size: Int?

    /// API URL for this object.
    public let url: String?

    public init(path: String, mode: String, type: String, sha: String? = nil, size: Int? = nil, url: String? = nil) {
        self.path = path
        self.mode = mode
        self.type = type
        self.sha = sha
        self.size = size
        self.url = url
    }
}

/// Parameters for creating a new tree.
public struct CreateTreeRequest: Encodable, Sendable {
    /// SHA of the base tree (for incremental updates). Omit to create from scratch.
    public let baseTree: String?

    /// The tree entries to create.
    public let tree: [CreateTreeEntry]

    public init(baseTree: String? = nil, tree: [CreateTreeEntry]) {
        self.baseTree = baseTree
        self.tree = tree
    }
}

/// An entry for creating a new tree.
///
/// Custom encoding ensures GitHub receives the correct fields:
/// - `.blob()`: sends `sha` only (no `content`)
/// - `.inlineBlob()`: sends `content` only (no `sha`)
/// - `.delete()`: sends `sha: null` only (no `content`)
public struct CreateTreeEntry: Sendable {
    /// File path.
    public let path: String

    /// File mode (e.g., `"100644"`).
    public let mode: String

    /// Object type (`"blob"`, `"tree"`, `"commit"`).
    public let type: String

    /// SHA of an existing blob (mutually exclusive with `content`).
    public let sha: String?

    /// File content as a string (GitHub creates the blob automatically).
    /// Mutually exclusive with `sha`. Use for small text files.
    public let content: String?

    /// Create an entry referencing an existing blob SHA.
    public static func blob(path: String, sha: String, mode: String = "100644") -> CreateTreeEntry {
        CreateTreeEntry(path: path, mode: mode, type: "blob", sha: sha, content: nil)
    }

    /// Create an entry with inline content (GitHub creates the blob).
    public static func inlineBlob(path: String, content: String, mode: String = "100644") -> CreateTreeEntry {
        CreateTreeEntry(path: path, mode: mode, type: "blob", sha: nil, content: content)
    }

    /// Create an entry that deletes a file (sha = null).
    public static func delete(path: String) -> CreateTreeEntry {
        CreateTreeEntry(path: path, mode: "100644", type: "blob", sha: nil, content: nil)
    }
}

extension CreateTreeEntry: Encodable {
    private enum CodingKeys: String, CodingKey {
        case path, mode, type, sha, content
    }

    /// Custom encoding: GitHub requires exactly one of `sha` or `content`.
    /// For delete, sends explicit `sha: null` without `content`.
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(mode, forKey: .mode)
        try container.encode(type, forKey: .type)

        if let sha {
            try container.encode(sha, forKey: .sha)
        } else if content == nil {
            // Delete: explicit null sha, no content
            try container.encodeNil(forKey: .sha)
        }
        // Only encode content when present (inlineBlob)
        try container.encodeIfPresent(content, forKey: .content)
    }
}
