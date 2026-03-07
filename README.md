# swift-github-api

A lightweight, async/await-first Swift client for GitHub's Git Data API.

Built for apps that use GitHub as a **file sync backend** — notes apps, static site generators, config managers, or anything that needs to read/write files in a GitHub repo without depending on the `git` binary.

## Features

- 🚀 **Modern Swift** — async/await, Sendable, Swift 6 strict concurrency
- 🌳 **Git Data API** — trees, blobs, commits, refs (the building blocks of git)
- 📱 **Cross-platform** — iOS 16+, macOS 13+, visionOS 1+
- 🔐 **Flexible auth** — PAT, OAuth token, or custom `AuthProvider`
- 🪶 **Zero dependencies** — just Foundation + URLSession

## Installation

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/mahopan/swift-github-api", from: "0.1.0"),
]

// Target
.target(dependencies: [
    .product(name: "GitHubAPI", package: "swift-github-api"),
])
```

## Quick Start

```swift
import GitHubAPI

let client = GitHubClient(token: "ghp_your_token")

// List all files in a repo
let tree = try await client.trees.get(owner: "user", repo: "notes", sha: "HEAD", recursive: true)
for entry in tree.tree where entry.type == "blob" {
    print(entry.path)
}

// Download a file
let blob = try await client.blobs.get(owner: "user", repo: "notes", sha: entry.sha!)
print(blob.decodedString ?? "binary")

// Push changes (create blob → tree → commit → update ref)
let newBlob = try await client.blobs.create(owner: "user", repo: "notes", request: .utf8("# Hello"))
let newTree = try await client.trees.create(owner: "user", repo: "notes", request: .init(
    baseTree: tree.sha,
    tree: [.blob(path: "hello.md", sha: newBlob.sha)]
))
let commit = try await client.commits.create(owner: "user", repo: "notes", request: .init(
    message: "Add hello.md",
    tree: newTree.sha,
    parents: [currentCommitSha]
))
try await client.refs.update(owner: "user", repo: "notes", ref: "heads/main",
    request: .init(sha: commit.sha))
```

## API Coverage

| Endpoint | Methods | Description |
|----------|---------|-------------|
| `client.repos` | `get` | Repository info + permissions check |
| `client.trees` | `get`, `create` | List/create Git tree objects |
| `client.blobs` | `get`, `create` | Read/write file content |
| `client.commits` | `get`, `create` | Read/create Git commits |
| `client.refs` | `get`, `update`, `create` | Read/update branch pointers |
| `client.contents` | `get` | Convenience for single file downloads |

## Custom Auth

```swift
// Implement AuthProvider for custom flows (e.g., Keychain, OAuth refresh)
struct KeychainAuth: AuthProvider {
    func token() async throws -> String {
        try Keychain.get("github-token")
    }
}

let client = GitHubClient(auth: KeychainAuth())
```

## GitHub Enterprise

```swift
let client = GitHubClient(
    token: "ghp_...",
    baseURL: URL(string: "https://github.example.com/api/v3")!
)
```

## Why not OctoKit.swift?

| | OctoKit.swift | swift-github-api |
|---|---|---|
| API style | Callback-based | async/await native |
| Git Data API | Limited | First-class (core focus) |
| Scope | Full GitHub API | Git Data + auth only |
| Swift Concurrency | Partial | Full (Sendable, actor-safe) |
| Dependencies | RequestKit | None |

## License

MIT — see [LICENSE](LICENSE).
