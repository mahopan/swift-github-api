import Foundation

/// A lightweight, async/await-first client for GitHub's REST API.
///
/// Focused on the Git Data API (trees, blobs, commits, refs) for building
/// file sync backends on top of GitHub repositories.
///
/// ```swift
/// let client = GitHubClient(token: "ghp_...")
/// let tree = try await client.trees.get(owner: "user", repo: "notes", sha: "HEAD")
/// ```
public final class GitHubClient: Sendable {
    /// The URLSession used for all requests.
    public let session: URLSession

    /// Base URL for the GitHub API (default: `https://api.github.com`).
    public let baseURL: URL

    /// Authentication provider.
    public let auth: any AuthProvider

    /// User-Agent header value.
    public let userAgent: String

    // MARK: - Endpoint Accessors

    /// Git trees API.
    public var trees: TreesEndpoint { TreesEndpoint(client: self) }

    /// Git blobs API.
    public var blobs: BlobsEndpoint { BlobsEndpoint(client: self) }

    /// Git commits API.
    public var commits: CommitsEndpoint { CommitsEndpoint(client: self) }

    /// Git references API.
    public var refs: RefsEndpoint { RefsEndpoint(client: self) }

    /// Repository info API.
    public var repos: ReposEndpoint { ReposEndpoint(client: self) }

    /// Repository contents API (convenience).
    public var contents: ContentsEndpoint { ContentsEndpoint(client: self) }

    // MARK: - Init

    /// Create a client with a personal access token or OAuth token.
    public convenience init(token: String, baseURL: URL? = nil, session: URLSession = .shared, userAgent: String = "swift-github-api") {
        self.init(auth: TokenAuth(token: token), baseURL: baseURL, session: session, userAgent: userAgent)
    }

    /// Create a client with a custom auth provider.
    public init(auth: any AuthProvider, baseURL: URL? = nil, session: URLSession = .shared, userAgent: String = "swift-github-api") {
        self.auth = auth
        self.baseURL = baseURL ?? URL(string: "https://api.github.com")!
        self.session = session
        self.userAgent = userAgent
    }

    // MARK: - Request Execution

    /// Execute an API request and decode the JSON response.
    public func request<T: Decodable & Sendable>(
        method: String = "GET",
        path: String,
        body: (any Encodable & Sendable)? = nil,
        query: [String: String]? = nil
    ) async throws -> T {
        let (data, response) = try await raw(method: method, path: path, body: body, query: query)
        try checkResponse(response, data: data)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(T.self, from: data)
    }

    /// Execute an API request and return raw data + response (for blobs, etc.).
    public func raw(
        method: String = "GET",
        path: String,
        body: (any Encodable & Sendable)? = nil,
        query: [String: String]? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var urlComponents = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        if let query {
            urlComponents.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
        }

        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = method
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        // Auth
        let token = try await auth.token()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        // Body
        if let body {
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .convertToSnakeCase
            request.httpBody = try encoder.encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        let (data, urlResponse) = try await session.data(for: request)
        guard let httpResponse = urlResponse as? HTTPURLResponse else {
            throw GitHubError.invalidResponse
        }

        return (data, httpResponse)
    }

    // MARK: - Response Handling

    private func checkResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
        case 401:
            throw GitHubError.unauthorized
        case 403:
            // Check for rate limit
            if let remaining = response.value(forHTTPHeaderField: "X-RateLimit-Remaining"),
               remaining == "0",
               let resetStr = response.value(forHTTPHeaderField: "X-RateLimit-Reset"),
               let resetTimestamp = Double(resetStr) {
                let resetDate = Date(timeIntervalSince1970: resetTimestamp)
                throw GitHubError.rateLimited(resetAt: resetDate)
            }
            throw GitHubError.forbidden(message: extractMessage(from: data))
        case 404:
            throw GitHubError.notFound(message: extractMessage(from: data))
        case 409:
            throw GitHubError.conflict(message: extractMessage(from: data))
        case 422:
            throw GitHubError.validationFailed(message: extractMessage(from: data))
        default:
            throw GitHubError.httpError(statusCode: response.statusCode, message: extractMessage(from: data))
        }
    }

    private func extractMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let message = json["message"] as? String {
            return message
        }
        return String(data: data, encoding: .utf8) ?? "Unknown error"
    }
}
