import XCTest
@testable import GitHubAPI

final class GitHubClientTests: XCTestCase {
    func testClientInitWithToken() {
        let client = GitHubClient(token: "ghp_test123")
        XCTAssertEqual(client.baseURL.absoluteString, "https://api.github.com")
        XCTAssertEqual(client.userAgent, "swift-github-api")
    }

    func testClientInitWithCustomBaseURL() {
        let client = GitHubClient(token: "ghp_test", baseURL: URL(string: "https://github.example.com/api/v3")!)
        XCTAssertEqual(client.baseURL.absoluteString, "https://github.example.com/api/v3")
    }

    func testTokenAuthProviderReturnsToken() async throws {
        let auth = TokenAuth(token: "my_token")
        let token = try await auth.token()
        XCTAssertEqual(token, "my_token")
    }
}
