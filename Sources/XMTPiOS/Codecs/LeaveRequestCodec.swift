import Foundation

public let ContentTypeLeaveRequest = ContentTypeID(
	authorityID: "xmtp.org",
	typeID: "leave_request",
	versionMajor: 1,
	versionMinor: 0
)

/// Represents a leave request message sent when a user wants to leave a group.
/// This content type is used to notify group members when a participant requests to leave.
///
/// - Note: Leave requests are automatically sent when calling `leaveGroup()` on a conversation.
///   You should not need to manually encode or send this content type. Following protobuf semantics,
///   empty `Data()` is treated as equivalent to `nil` during encoding/decoding.
public struct LeaveRequest: Codable, Equatable {
	/// Optional authenticated note for the leave request.
	/// Can contain additional context or reason for leaving.
	///
	/// - Important: Empty data is normalized to `nil` to align with protobuf wire format semantics.
	public var authenticatedNote: Data?

	public init(authenticatedNote: Data? = nil) {
		self.authenticatedNote = authenticatedNote
	}
}
