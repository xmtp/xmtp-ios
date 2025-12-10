import Foundation

public let ContentTypeLeaveRequest = ContentTypeID(
	authorityID: "xmtp.org",
	typeID: "leave_request",
	versionMajor: 1,
	versionMinor: 0
)

/// Represents a leave request message sent when a user wants to leave a group.
public struct LeaveRequest {
	/// Optional authenticated note for the leave request
	public var authenticatedNote: Data?

	public init(authenticatedNote: Data? = nil) {
		self.authenticatedNote = authenticatedNote
	}
}

public struct LeaveRequestCodec: ContentCodec {
	public typealias T = LeaveRequest

	public init() {}

	public var contentType = ContentTypeLeaveRequest

	public func encode(content: LeaveRequest) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeLeaveRequest
		if let note = content.authenticatedNote {
			encodedContent.content = note
		}

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
