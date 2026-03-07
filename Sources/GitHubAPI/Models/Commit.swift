import Foundation

/// A Git commit object from the GitHub API.
public struct GitCommit: Codable, Sendable {
    /// SHA of this commit.
    public let sha: String

    /// Commit message.
    public let message: String?

    /// The tree this commit points to.
    public let tree: ObjectRef?

    /// Parent commits.
    public let parents: [ObjectRef]?

    /// Author info.
    public let author: CommitPerson?

    /// Committer info.
    public let committer: CommitPerson?

    public init(sha: String, message: String? = nil, tree: ObjectRef? = nil, parents: [ObjectRef]? = nil, author: CommitPerson? = nil, committer: CommitPerson? = nil) {
        self.sha = sha
        self.message = message
        self.tree = tree
        self.parents = parents
        self.author = author
        self.committer = committer
    }
}

/// A reference to a Git object (tree, commit, blob) by SHA.
public struct ObjectRef: Codable, Sendable {
    public let sha: String
    public let url: String?

    public init(sha: String, url: String? = nil) {
        self.sha = sha
        self.url = url
    }
}

/// Author or committer information.
public struct CommitPerson: Codable, Sendable {
    public let name: String
    public let email: String
    public let date: Date?

    public init(name: String, email: String, date: Date? = nil) {
        self.name = name
        self.email = email
        self.date = date
    }
}

/// Parameters for creating a new commit.
public struct CreateCommitRequest: Encodable, Sendable {
    /// Commit message.
    public let message: String

    /// SHA of the tree object.
    public let tree: String

    /// SHAs of parent commits.
    public let parents: [String]

    /// Optional author override.
    public let author: CommitPerson?

    public init(message: String, tree: String, parents: [String], author: CommitPerson? = nil) {
        self.message = message
        self.tree = tree
        self.parents = parents
        self.author = author
    }
}
