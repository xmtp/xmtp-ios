import Foundation
import XCTest
import XMTPTestHelpers

@testable import XMTPiOS

@available(iOS 16, *)
class LeaveRequestTests: XCTestCase {
	override func setUp() {
		super.setUp()
		setupLocalEnv()
	}

	func testLeaveRequestMessageIsDecodedProperly() async throws {
		let fixtures = try await fixtures()

		// Alix creates a group with Bo
		let alixGroup = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID]
		)

		// Bo syncs and gets the group
		_ = try await fixtures.boClient.conversations.syncAllConversations()
		let boGroup = try XCTUnwrap(
			fixtures.boClient.conversations.findGroup(groupId: alixGroup.id)
		)

		// Bo leaves the group - this creates a LeaveRequest message
		try await boGroup.leaveGroup()

		// Alix syncs to receive the leave request
		try await alixGroup.sync()

		// Wait for the admin worker to process the removal
		try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

		// Alix syncs again to get the messages
		try await alixGroup.sync()

		// Get enriched messages - this goes through DecodedMessageV2 which decodes LeaveRequest
		let messages = try await alixGroup.enrichedMessages()

		// Find the messages from Bo (the leave request)
		let boMessages = messages.filter { $0.senderInboxId == fixtures.boClient.inboxID }
		XCTAssertTrue(!boMessages.isEmpty, "Bo should have sent at least one message")

		// Find the leave request message by checking for LeaveRequest content type
		let leaveRequestMessage = boMessages.first { msg in
			msg.contentTypeId == ContentTypeLeaveRequest
		}

		XCTAssertNotNil(
			leaveRequestMessage,
			"LeaveRequest message should be properly decoded with correct content type"
		)

		// Verify we can decode the content as LeaveRequest
		if let leaveMsg = leaveRequestMessage {
			let leaveRequest: LeaveRequest = try leaveMsg.content()
			XCTAssertNotNil(leaveRequest, "Should be able to decode LeaveRequest content")
		}

		try fixtures.cleanUpDatabases()
	}

	func testLeaveRequestContentTypeIsCorrect() async throws {
		let fixtures = try await fixtures()

		// Alix creates a group with Bo
		let alixGroup = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID]
		)

		// Bo syncs and gets the group
		_ = try await fixtures.boClient.conversations.syncAllConversations()
		let boGroup = try XCTUnwrap(
			fixtures.boClient.conversations.findGroup(groupId: alixGroup.id)
		)

		// Bo leaves the group
		try await boGroup.leaveGroup()

		// Alix syncs
		try await alixGroup.sync()
		try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
		try await alixGroup.sync()

		// Get enriched messages
		let messages = try await alixGroup.enrichedMessages()

		// Get all content types present
		let contentTypes = Set(messages.map(\.contentTypeId))

		// Verify LeaveRequest content type format
		if let leaveRequestType = contentTypes.first(where: { $0.typeID == "leave_request" }) {
			XCTAssertEqual(leaveRequestType.authorityID, "xmtp.org")
			XCTAssertEqual(leaveRequestType.typeID, "leave_request")
			XCTAssertEqual(leaveRequestType.versionMajor, 1)
			XCTAssertEqual(leaveRequestType.versionMinor, 0)
		}

		try fixtures.cleanUpDatabases()
	}

	func testLeaveRequestFallbackText() async throws {
		let fixtures = try await fixtures()

		// Alix creates a group with Bo
		let alixGroup = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID]
		)

		// Bo syncs and gets the group
		_ = try await fixtures.boClient.conversations.syncAllConversations()
		let boGroup = try XCTUnwrap(
			fixtures.boClient.conversations.findGroup(groupId: alixGroup.id)
		)

		// Bo leaves the group
		try await boGroup.leaveGroup()

		// Alix syncs
		try await alixGroup.sync()
		try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
		try await alixGroup.sync()

		// Get enriched messages
		let messages = try await alixGroup.enrichedMessages()

		// Find the leave request message
		let leaveRequestMessage = messages.first { msg in
			msg.contentTypeId == ContentTypeLeaveRequest
		}

		// If we found a leave request message, verify the body falls back properly
		if let leaveMsg = leaveRequestMessage {
			// The body property should return the fallback text when content isn't a String
			let body = try leaveMsg.body
			XCTAssertFalse(body.isEmpty, "Leave request should have fallback text")
		}

		try fixtures.cleanUpDatabases()
	}
}
