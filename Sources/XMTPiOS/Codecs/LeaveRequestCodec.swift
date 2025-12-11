import Foundation

public let ContentTypeLeaveRequest = ContentTypeID(
	authorityID: "xmtp.org",
	typeID: "leave_request",
	versionMajor: 1,
	versionMinor: 0
)

/// Represents a leave request message sent when a user wants to leave a group.
/// This content type is used to notify group members when a participant requests to leave.
public struct LeaveRequest: Codable, Equatable {
	/// Optional authenticated note for the leave request.
	/// Can contain additional context or reason for leaving.
	public var authenticatedNote: Data?

	public init(authenticatedNote: Data? = nil) {
		self.authenticatedNote = authenticatedNote
	}
}

/// Codec for encoding and decoding `LeaveRequest` content types.
/// Used when a group member wants to leave a conversation.
public struct LeaveRequestCodec: ContentCodec {
	public typealias T = LeaveRequest

	public init() {}

	public var contentType = ContentTypeLeaveRequest

	public func encode(content: LeaveRequest) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeLeaveRequest
		// Always set content to maintain encode/decode symmetry
		encodedContent.content = content.authenticatedNote ?? Data()

		return encodedContent
	}

	public func decode(content: EncodedContent) throws -> LeaveRequest {
		LeaveRequest(
			authenticatedNote: content.content.isEmpty ? nil : content.content
		)
	}

	public func fallback(content _: LeaveRequest) throws -> String? {
		"A member has requested to leave the group"
	}

	public func shouldPush(content _: LeaveRequest) throws -> Bool {
		false
	}
}
