import Foundation

/// Repository metadata from the GitHub API.
public struct Repository: Codable, Sendable {
    public let id: Int
    public let name: String
    public let fullName: String
    public let owner: RepositoryOwner
    public let isPrivate: Bool
    public let description: String?
    public let defaultBranch: String
    public let permissions: RepositoryPermissions?

    private enum CodingKeys: String, CodingKey {
        case id, name, fullName, owner, description, defaultBranch, permissions
        case isPrivate = "private"
    }

    public init(id: Int, name: String, fullName: String, owner: RepositoryOwner, isPrivate: Bool, description: String? = nil, defaultBranch: String = "main", permissions: RepositoryPermissions? = nil) {
        self.id = id
        self.name = name
        self.fullName = fullName
        self.owner = owner
        self.isPrivate = isPrivate
        self.description = description
        self.defaultBranch = defaultBranch
        self.permissions = permissions
    }
}

/// Repository owner info.
public struct RepositoryOwner: Codable, Sendable {
    public let login: String
    public let id: Int

    public init(login: String, id: Int) {
        self.login = login
        self.id = id
    }
}

/// Repository permission levels for the authenticated user.
public struct RepositoryPermissions: Codable, Sendable {
    public let admin: Bool?
    public let maintain: Bool?
    public let push: Bool?
    public let triage: Bool?
    public let pull: Bool?

    public init(admin: Bool? = nil, maintain: Bool? = nil, push: Bool? = nil, triage: Bool? = nil, pull: Bool? = nil) {
        self.admin = admin
        self.maintain = maintain
        self.push = push
        self.triage = triage
        self.pull = pull
    }
}
