import XCTest
@testable import GitHubAPI

final class ModelTests: XCTestCase {

    // MARK: - Blob

    func testBlobDecodedString() {
        let content = Data("Hello, World!".utf8).base64EncodedString()
        let blob = GitBlob(sha: "abc123", content: content, encoding: "base64", size: 13)
        XCTAssertEqual(blob.decodedString, "Hello, World!")
    }

    func testBlobDecodedDataNilForNonBase64() {
        let blob = GitBlob(sha: "abc123", content: "plain text", encoding: "utf-8")
        XCTAssertNil(blob.decodedData)
    }

    func testBlobBase64WithNewlines() {
        // GitHub returns base64 with line breaks
        let original = String(repeating: "A", count: 200)
        var b64 = Data(original.utf8).base64EncodedString()
        b64.insert("\n", at: b64.index(b64.startIndex, offsetBy: 76))
        let blob = GitBlob(sha: "abc", content: b64, encoding: "base64")
        XCTAssertEqual(blob.decodedString, original)
    }

    // MARK: - CreateBlobRequest

    func testCreateBlobUTF8() {
        let req = CreateBlobRequest.utf8("# Hello")
        XCTAssertEqual(req.content, "# Hello")
        XCTAssertEqual(req.encoding, "utf-8")
    }

    func testCreateBlobBase64() {
        let data = Data([0x89, 0x50, 0x4E, 0x47]) // PNG header
        let req = CreateBlobRequest.base64(data)
        XCTAssertEqual(req.encoding, "base64")
        XCTAssertEqual(Data(base64Encoded: req.content), data)
    }

    // MARK: - TreeEntry

    func testCreateTreeEntryBlob() {
        let entry = CreateTreeEntry.blob(path: "notes/hello.md", sha: "abc123")
        XCTAssertEqual(entry.path, "notes/hello.md")
        XCTAssertEqual(entry.mode, "100644")
        XCTAssertEqual(entry.type, "blob")
        XCTAssertEqual(entry.sha, "abc123")
        XCTAssertNil(entry.content)
    }

    func testCreateTreeEntryInlineBlob() {
        let entry = CreateTreeEntry.inlineBlob(path: "README.md", content: "# README")
        XCTAssertEqual(entry.path, "README.md")
        XCTAssertNil(entry.sha)
        XCTAssertEqual(entry.content, "# README")
    }

    func testCreateTreeEntryDelete() {
        let entry = CreateTreeEntry.delete(path: "old-file.md")
        XCTAssertEqual(entry.path, "old-file.md")
        XCTAssertNil(entry.sha)
        XCTAssertNil(entry.content)
    }

    // MARK: - JSON Decoding (snake_case)

    func testTreeDecoding() throws {
        let json = """
        {
            "sha": "tree123",
            "tree": [
                {"path": "hello.md", "mode": "100644", "type": "blob", "sha": "blob456", "size": 42}
            ],
            "truncated": false
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let tree = try decoder.decode(GitTree.self, from: json)

        XCTAssertEqual(tree.sha, "tree123")
        XCTAssertEqual(tree.tree.count, 1)
        XCTAssertEqual(tree.tree[0].path, "hello.md")
        XCTAssertEqual(tree.tree[0].size, 42)
        XCTAssertEqual(tree.truncated, false)
    }

    func testRepositoryDecoding() throws {
        let json = """
        {
            "id": 12345,
            "name": "maho-vault",
            "full_name": "kuochuanpan/maho-vault",
            "private": true,
            "default_branch": "main",
            "owner": {"login": "kuochuanpan", "id": 1},
            "permissions": {"admin": false, "push": true, "pull": true}
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let repo = try decoder.decode(Repository.self, from: json)

        XCTAssertEqual(repo.name, "maho-vault")
        XCTAssertTrue(repo.isPrivate)
        XCTAssertEqual(repo.defaultBranch, "main")
        XCTAssertEqual(repo.permissions?.push, true)
    }
}
