import XCTest
@testable import GitHubAPI

final class OAuthTests: XCTestCase {

    let config = OAuthConfiguration(
        clientId: "Iv1.test123",
        clientSecret: "test_secret",
        redirectURI: "mahonotes://github-callback",
        scopes: ["repo"]
    )

    // MARK: - OAuthConfiguration

    func testAuthorizationURL() {
        let url = config.authorizationURL(state: "random123")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!

        XCTAssertEqual(components.host, "github.com")
        XCTAssertTrue(components.path.contains("login/oauth/authorize"))

        let params = Dictionary(uniqueKeysWithValues: components.queryItems!.map { ($0.name, $0.value!) })
        XCTAssertEqual(params["client_id"], "Iv1.test123")
        XCTAssertEqual(params["redirect_uri"], "mahonotes://github-callback")
        XCTAssertEqual(params["scope"], "repo")
        XCTAssertEqual(params["state"], "random123")
    }

    func testAuthorizationURLMultipleScopes() {
        let multiConfig = OAuthConfiguration(
            clientId: "test",
            redirectURI: "app://cb",
            scopes: ["repo", "read:user"]
        )
        let url = multiConfig.authorizationURL(state: "s")
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        let scope = components.queryItems?.first(where: { $0.name == "scope" })?.value
        XCTAssertEqual(scope, "repo read:user")
    }

    func testCustomBaseURL() {
        let ghes = OAuthConfiguration(
            clientId: "test",
            redirectURI: "app://cb",
            baseURL: URL(string: "https://github.example.com")!
        )
        let url = ghes.authorizationURL(state: "s")
        XCTAssertEqual(url.host, "github.example.com")
    }

    func testTokenURL() {
        XCTAssertEqual(config.tokenURL.absoluteString, "https://github.com/login/oauth/access_token")
    }

    // MARK: - OAuthTokenExchange

    func testExtractCodeSuccess() throws {
        let exchange = OAuthTokenExchange(configuration: config)
        let callbackURL = URL(string: "mahonotes://github-callback?code=abc123&state=mystate")!
        let code = try exchange.extractCode(from: callbackURL, expectedState: "mystate")
        XCTAssertEqual(code, "abc123")
    }

    func testExtractCodeMissingState() {
        let exchange = OAuthTokenExchange(configuration: config)
        let callbackURL = URL(string: "mahonotes://github-callback?code=abc123")!
        XCTAssertThrowsError(try exchange.extractCode(from: callbackURL, expectedState: "mystate")) { error in
            guard case OAuthError.missingState = error else {
                XCTFail("Expected missingState, got \(error)")
                return
            }
        }
    }

    func testExtractCodeStateMismatch() {
        let exchange = OAuthTokenExchange(configuration: config)
        let callbackURL = URL(string: "mahonotes://github-callback?code=abc&state=wrong")!
        XCTAssertThrowsError(try exchange.extractCode(from: callbackURL, expectedState: "expected")) { error in
            guard case OAuthError.stateMismatch(let expected, let received) = error else {
                XCTFail("Expected stateMismatch, got \(error)")
                return
            }
            XCTAssertEqual(expected, "expected")
            XCTAssertEqual(received, "wrong")
        }
    }

    func testExtractCodeMissingCode() {
        let exchange = OAuthTokenExchange(configuration: config)
        let callbackURL = URL(string: "mahonotes://github-callback?state=mystate")!
        XCTAssertThrowsError(try exchange.extractCode(from: callbackURL, expectedState: "mystate")) { error in
            guard case OAuthError.missingCode = error else {
                XCTFail("Expected missingCode, got \(error)")
                return
            }
        }
    }

    func testExtractCodeAuthDenied() {
        let exchange = OAuthTokenExchange(configuration: config)
        let callbackURL = URL(string: "mahonotes://github-callback?error=access_denied&error_description=The%20user%20denied")!
        XCTAssertThrowsError(try exchange.extractCode(from: callbackURL, expectedState: "s")) { error in
            guard case OAuthError.authorizationDenied(let err, let desc) = error else {
                XCTFail("Expected authorizationDenied, got \(error)")
                return
            }
            XCTAssertEqual(err, "access_denied")
            XCTAssertEqual(desc, "The user denied")
        }
    }

    // MARK: - OAuthTokenResponse

    func testTokenResponseDecoding() throws {
        let json = """
        {
            "access_token": "gho_abc123",
            "token_type": "bearer",
            "scope": "repo,read:user"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: json)
        XCTAssertEqual(response.accessToken, "gho_abc123")
        XCTAssertEqual(response.tokenType, "bearer")
        XCTAssertEqual(response.scope, "repo,read:user")
        XCTAssertEqual(response.scopeArray, ["repo", "read:user"])
        XCTAssertNil(response.refreshToken)
        XCTAssertNil(response.expiresIn)
    }

    func testTokenResponseWithRefresh() throws {
        let json = """
        {
            "access_token": "gho_abc",
            "token_type": "bearer",
            "scope": "repo",
            "refresh_token": "ghr_xyz",
            "expires_in": 28800,
            "refresh_token_expires_in": 15811200
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OAuthTokenResponse.self, from: json)
        XCTAssertEqual(response.refreshToken, "ghr_xyz")
        XCTAssertEqual(response.expiresIn, 28800)
        XCTAssertEqual(response.refreshTokenExpiresIn, 15811200)
    }

    // MARK: - OAuthAuth

    func testOAuthAuthSimple() async throws {
        let auth = OAuthAuth(accessToken: "gho_test123")
        let token = try await auth.token()
        XCTAssertEqual(token, "gho_test123")
    }

    // MARK: - OAuthError

    func testOAuthErrorDescriptions() {
        let errors: [(OAuthError, String)] = [
            (.cancelled, "cancelled"),
            (.missingCode, "missing"),
            (.missingState, "state"),
            (.noPresentationAnchor, "anchor"),
        ]
        for (error, keyword) in errors {
            XCTAssertTrue(error.description.lowercased().contains(keyword),
                         "\(error.description) should contain '\(keyword)'")
        }
    }
}
