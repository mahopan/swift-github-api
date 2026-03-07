import Foundation

/// Response from GitHub's device code request (`POST /login/device/code`).
///
/// Contains the user code to display and the device code for polling.
public struct DeviceCodeResponse: Codable, Sendable {
    /// The device verification code (used internally for polling).
    public let deviceCode: String

    /// The user verification code to display to the user.
    public let userCode: String

    /// The URL where the user should enter the code.
    public let verificationUri: String

    /// Seconds until the device and user codes expire.
    public let expiresIn: Int

    /// Minimum polling interval in seconds.
    public let interval: Int

    private enum CodingKeys: String, CodingKey {
        case deviceCode = "device_code"
        case userCode = "user_code"
        case verificationUri = "verification_uri"
        case expiresIn = "expires_in"
        case interval
    }
}
