import Foundation

/// A Git reference (branch/tag pointer).
public struct GitRef: Codable, Sendable {
    /// Full ref name (e.g., `"refs/heads/main"`).
    public let ref: String

    /// The object this ref points to.
    public let object: RefObject

    public init(ref: String, object: RefObject) {
        self.ref = ref
        self.object = object
    }
}

/// The object a ref points to.
public struct RefObject: Codable, Sendable {
    /// Object type (`"commit"`, `"tag"`, etc.).
    public let type: String

    /// SHA of the object.
    public let sha: String

    public init(type: String, sha: String) {
        self.type = type
        self.sha = sha
    }
}

/// Parameters for updating a ref.
public struct UpdateRefRequest: Encodable, Sendable {
    /// New SHA to point to.
    public let sha: String

    /// Force update (non-fast-forward). Default: `false`.
    public let force: Bool

    public init(sha: String, force: Bool = false) {
        self.sha = sha
        self.force = force
    }
}
