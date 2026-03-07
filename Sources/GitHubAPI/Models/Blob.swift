import Foundation

/// A Git blob object from the GitHub API.
public struct GitBlob: Codable, Sendable {
    /// SHA of this blob.
    public let sha: String

    /// Content of the blob (base64-encoded when `encoding` is `"base64"`).
    public let content: String?

    /// Encoding of the content field (`"base64"` or `"utf-8"`).
    public let encoding: String?

    /// Size in bytes.
    public let size: Int?

    public init(sha: String, content: String? = nil, encoding: String? = nil, size: Int? = nil) {
        self.sha = sha
        self.content = content
        self.encoding = encoding
        self.size = size
    }

    /// Decode the base64 content to Data.
    public var decodedData: Data? {
        guard let content, encoding == "base64" else { return nil }
        // GitHub base64 may contain newlines
        let cleaned = content.replacingOccurrences(of: "\n", with: "")
        return Data(base64Encoded: cleaned)
    }

    /// Decode the base64 content to a UTF-8 string.
    public var decodedString: String? {
        guard let data = decodedData else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

/// Parameters for creating a new blob.
public struct CreateBlobRequest: Encodable, Sendable {
    /// Content of the blob.
    public let content: String

    /// Encoding: `"utf-8"` (default) or `"base64"`.
    public let encoding: String

    /// Create a blob from a UTF-8 string.
    public static func utf8(_ content: String) -> CreateBlobRequest {
        CreateBlobRequest(content: content, encoding: "utf-8")
    }

    /// Create a blob from base64-encoded data.
    public static func base64(_ data: Data) -> CreateBlobRequest {
        CreateBlobRequest(content: data.base64EncodedString(), encoding: "base64")
    }
}
