import Foundation

/// GitHub Device Flow (OAuth 2.0 Device Authorization Grant).
///
/// Implements the full device flow: request a user code, then poll for the token
/// after the user authorizes on `github.com/login/device`.
///
/// ```swift
/// let config = DeviceFlowConfiguration(clientId: "Iv1.abc123", scopes: ["repo"])
/// let flow = DeviceFlow(configuration: config)
///
/// // Step 1: Get the user code
/// let code = try await flow.requestCode()
/// print("Go to \(code.verificationUri) and enter: \(code.userCode)")
///
/// // Step 2: Poll until the user authorizes (or code expires)
/// let token = try await flow.pollForToken(deviceCode: code)
/// print(token.accessToken) // Store in Keychain
/// ```
///
/// - Note: Does not require a client secret — safe for App Store distribution.
public struct DeviceFlow: Sendable {
    /// Device Flow configuration.
    public let configuration: DeviceFlowConfiguration

    /// URLSession to use for requests.
    public let session: URLSession

    public init(configuration: DeviceFlowConfiguration, session: URLSession = .shared) {
        self.configuration = configuration
        self.session = session
    }

    // MARK: - Step 1: Request Device Code

    /// Request a device and user verification code from GitHub.
    ///
    /// - Returns: A `DeviceCodeResponse` containing the user code to display.
    /// - Throws: `OAuthError` if the request fails.
    public func requestCode() async throws -> DeviceCodeResponse {
        var request = URLRequest(url: configuration.deviceCodeURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "client_id=\(configuration.clientId)",
            "scope=\(configuration.scopes.joined(separator: " "))",
        ]
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            if let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) {
                throw OAuthError.tokenExchangeFailed(
                    error: errorResponse.error,
                    description: errorResponse.errorDescription
                )
            }
            throw OAuthError.httpError(statusCode: httpResponse.statusCode)
        }

        return try JSONDecoder().decode(DeviceCodeResponse.self, from: data)
    }

    // MARK: - Step 2: Poll for Token

    /// Poll GitHub until the user authorizes or the code expires.
    ///
    /// This method blocks (with `Task.sleep`) between polls, respecting the
    /// server-specified interval. It handles `authorization_pending` and
    /// `slow_down` responses automatically.
    ///
    /// - Parameter deviceCode: The `DeviceCodeResponse` from `requestCode()`.
    /// - Returns: The token response containing the access token.
    /// - Throws: `OAuthError` if the user denies, code expires, or polling fails.
    public func pollForToken(deviceCode: DeviceCodeResponse) async throws -> OAuthTokenResponse {
        var interval = deviceCode.interval
        let deadline = Date().addingTimeInterval(TimeInterval(deviceCode.expiresIn))

        while Date() < deadline {
            try Task.checkCancellation()
            try await Task.sleep(for: .seconds(interval))

            let result = try await pollOnce(deviceCode: deviceCode.deviceCode)

            switch result {
            case .success(let token):
                return token
            case .pending:
                continue
            case .slowDown:
                interval += 5  // GitHub asks us to slow down
                continue
            }
        }

        throw OAuthError.tokenExchangeFailed(error: "expired_token", description: "The device code has expired. Please restart the flow.")
    }

    // MARK: - Private

    private enum PollResult {
        case success(OAuthTokenResponse)
        case pending
        case slowDown
    }

    private func pollOnce(deviceCode: String) async throws -> PollResult {
        var request = URLRequest(url: configuration.tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "client_id=\(configuration.clientId)",
            "device_code=\(deviceCode)",
            "grant_type=urn:ietf:params:oauth:grant-type:device_code",
        ]
        request.httpBody = bodyParams.joined(separator: "&").data(using: .utf8)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.invalidResponse
        }

        guard httpResponse.statusCode == 200 else {
            throw OAuthError.httpError(statusCode: httpResponse.statusCode)
        }

        // Try to decode as a successful token response first
        if let token = try? JSONDecoder().decode(OAuthTokenResponse.self, from: data) {
            return .success(token)
        }

        // Otherwise, decode as an error response
        guard let errorResponse = try? JSONDecoder().decode(OAuthErrorResponse.self, from: data) else {
            throw OAuthError.invalidResponse
        }

        switch errorResponse.error {
        case "authorization_pending":
            return .pending
        case "slow_down":
            return .slowDown
        case "expired_token":
            throw OAuthError.tokenExchangeFailed(error: "expired_token", description: "The device code has expired. Please restart the flow.")
        case "access_denied":
            throw OAuthError.authorizationDenied(error: "access_denied", description: "The user denied the authorization request.")
        case "unsupported_grant_type":
            throw OAuthError.tokenExchangeFailed(error: "unsupported_grant_type", description: "Device Flow is not enabled for this OAuth App. Enable it in GitHub Developer Settings.")
        default:
            throw OAuthError.tokenExchangeFailed(error: errorResponse.error, description: errorResponse.errorDescription)
        }
    }
}
