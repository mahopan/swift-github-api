import XCTest
@testable import GitHubAPI

/// Live integration tests against real GitHub API.
///
/// These tests require a valid GitHub token and are **skipped by default**.
/// To run:
/// ```
/// GITHUB_TOKEN=ghp_xxx swift test --filter IntegrationTests
/// ```
///
/// Tests use `kuochuanpan/maho-getting-started` (public repo) for read-only tests
/// and a dedicated test branch for write tests.
final class IntegrationTests: XCTestCase {

    // Test against a public repo — safe for read operations
    let owner = "kuochuanpan"
    let repo = "maho-getting-started"
    let branch = "main"

    var client: GitHubClient!

    override func setUp() async throws {
        guard let token = ProcessInfo.processInfo.environment["GITHUB_TOKEN"] else {
            throw XCTSkip("GITHUB_TOKEN not set — skipping integration tests")
        }
        client = GitHubClient(token: token)
    }

    // MARK: - Repos

    func testGetRepo() async throws {
        let repo = try await client.repos.get(owner: owner, repo: self.repo)
        XCTAssertEqual(repo.name, self.repo)
        XCTAssertEqual(repo.owner.login, owner)
        XCTAssertEqual(repo.defaultBranch, "main")
    }

    // MARK: - Refs

    func testGetRef() async throws {
        let ref = try await client.refs.get(owner: owner, repo: repo, ref: "heads/\(branch)")
        XCTAssertEqual(ref.ref, "refs/heads/\(branch)")
        XCTAssertEqual(ref.object.type, "commit")
        XCTAssertFalse(ref.object.sha.isEmpty)
    }

    // MARK: - Commits

    func testGetCommit() async throws {
        // First get HEAD SHA
        let ref = try await client.refs.get(owner: owner, repo: repo, ref: "heads/\(branch)")
        let commit = try await client.commits.get(owner: owner, repo: repo, sha: ref.object.sha)
        XCTAssertEqual(commit.sha, ref.object.sha)
        XCTAssertNotNil(commit.message)
        XCTAssertNotNil(commit.tree)
        XCTAssertNotNil(commit.author)
    }

    // MARK: - Trees

    func testGetTree() async throws {
        // Get HEAD tree recursively
        let ref = try await client.refs.get(owner: owner, repo: repo, ref: "heads/\(branch)")
        let commit = try await client.commits.get(owner: owner, repo: repo, sha: ref.object.sha)
        let tree = try await client.trees.get(owner: owner, repo: repo, sha: commit.tree!.sha, recursive: true)

        XCTAssertFalse(tree.tree.isEmpty)
        XCTAssertFalse(tree.sha.isEmpty)

        // Should contain at least a README or some markdown files
        let mdFiles = tree.tree.filter { $0.path.hasSuffix(".md") }
        XCTAssertFalse(mdFiles.isEmpty, "Expected at least one .md file")

        // All blob entries should have SHA
        for entry in tree.tree where entry.type == "blob" {
            XCTAssertNotNil(entry.sha)
            XCTAssertEqual(entry.mode, "100644")
        }
    }

    // MARK: - Blobs

    func testGetBlob() async throws {
        // Get a known file
        let ref = try await client.refs.get(owner: owner, repo: repo, ref: "heads/\(branch)")
        let commit = try await client.commits.get(owner: owner, repo: repo, sha: ref.object.sha)
        let tree = try await client.trees.get(owner: owner, repo: repo, sha: commit.tree!.sha, recursive: true)

        // Find a markdown file
        guard let mdFile = tree.tree.first(where: { $0.path.hasSuffix(".md") && $0.type == "blob" }) else {
            XCTFail("No markdown file found")
            return
        }

        let blob = try await client.blobs.get(owner: owner, repo: repo, sha: mdFile.sha!)
        XCTAssertEqual(blob.sha, mdFile.sha)
        XCTAssertEqual(blob.encoding, "base64")
        XCTAssertNotNil(blob.decodedString, "Should decode to a string")
    }

    // MARK: - Contents

    func testGetContents() async throws {
        // Get a file via Contents API
        let ref = try await client.refs.get(owner: owner, repo: repo, ref: "heads/\(branch)")
        let commit = try await client.commits.get(owner: owner, repo: repo, sha: ref.object.sha)
        let tree = try await client.trees.get(owner: owner, repo: repo, sha: commit.tree!.sha, recursive: true)

        guard let mdFile = tree.tree.first(where: { $0.path.hasSuffix(".md") && $0.type == "blob" }) else {
            XCTFail("No markdown file found")
            return
        }

        let content = try await client.contents.get(owner: owner, repo: repo, path: mdFile.path)
        XCTAssertEqual(content.path, mdFile.path)
        XCTAssertEqual(content.type, "file")
        XCTAssertNotNil(content.decodedString)
    }

    // MARK: - Error Handling

    func testNotFound() async throws {
        do {
            _ = try await client.repos.get(owner: owner, repo: "definitely-does-not-exist-xyz-123")
            XCTFail("Should have thrown")
        } catch let error as GitHubError {
            guard case .notFound = error else {
                XCTFail("Expected notFound, got \(error)")
                return
            }
        }
    }

    // MARK: - Full Sync Flow (Read-Only Simulation)

    /// Simulates what GitHubSyncManager.pull() would do — read-only.
    func testSyncFlowReadOnly() async throws {
        // 1. Get branch HEAD
        let ref = try await client.refs.get(owner: owner, repo: repo, ref: "heads/\(branch)")
        let headSHA = ref.object.sha

        // 2. Get commit → tree SHA
        let commit = try await client.commits.get(owner: owner, repo: repo, sha: headSHA)
        let treeSHA = commit.tree!.sha

        // 3. Get full tree
        let tree = try await client.trees.get(owner: owner, repo: repo, sha: treeSHA, recursive: true)

        // 4. For each blob, we could download (just check first one here)
        let blobs = tree.tree.filter { $0.type == "blob" }
        XCTAssertFalse(blobs.isEmpty)

        if let first = blobs.first {
            let blob = try await client.blobs.get(owner: owner, repo: repo, sha: first.sha!)
            XCTAssertNotNil(blob.decodedData)
        }

        // This proves the full read path works:
        // ref → commit → tree → blobs → file content ✅
    }
}
