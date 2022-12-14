//
//  ConversationTests.swift
//
//
//  Created by Pat Nakajima on 12/6/22.
//

import XCTest
@testable import XMTP

@available(iOS 16, *)
class ConversationTests: XCTestCase {
	var fakeApiClient: FakeApiClient!

	var alice: PrivateKey!
	var aliceClient: Client!

	var bob: PrivateKey!
	var bobClient: Client!

	override func setUp() async throws {
		alice = try PrivateKey.generate()
		bob = try PrivateKey.generate()

		fakeApiClient = FakeApiClient()

		aliceClient = try await Client.create(account: alice, apiClient: fakeApiClient)
		bobClient = try await Client.create(account: bob, apiClient: fakeApiClient)
	}

	func testCanStreamConversationsV1() async throws {
		// Overwrite contact as legacy
		try await publishLegacyContact(client: bobClient)
		try await publishLegacyContact(client: aliceClient)

		let expectation = expectation(description: "got a conversation")

		Task(priority: .userInitiated) {
			for try await conversation in aliceClient.conversations.stream() {
				if conversation.peerAddress == bob.walletAddress {
					expectation.fulfill()
				}
			}
		}

		guard case let .v1(conversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
			XCTFail("Did not create a v1 convo")
			return
		}

		try await conversation.send(content: "hi")

		// Remove known introduction from contacts to test de-duping
		bobClient.contacts.hasIntroduced.removeAll()

		try await conversation.send(content: "hi again")

		await waitForExpectations(timeout: 5)
	}

	func testCanStreamConversationsV2() async throws {
		let expectation = expectation(description: "got a conversation")

		Task(priority: .userInitiated) {
			for try await conversation in aliceClient.conversations.stream() {
				if conversation.peerAddress == bob.walletAddress {
					expectation.fulfill()
				}
			}
		}

		guard case let .v2(conversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
			XCTFail("Did not create a v1 convo")
			return
		}

		try await conversation.send(content: "hi")

		// Remove known introduction from contacts to test de-duping
		bobClient.contacts.hasIntroduced.removeAll()
		bobClient.contacts.knownBundles.removeAll()
		bobClient.conversations.conversations.removeAll()

		guard case let .v2(conversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
			XCTFail("Did not create a v1 convo")
			return
		}

		try await conversation.send(content: "hi again")

		await waitForExpectations(timeout: 3)
	}

	func testCanUseCachedConversation() async throws {
		guard case .v2 = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
			XCTFail("Did not get a v2 convo")
			return
		}

		try await fakeApiClient.assertNoQuery {
			guard case .v2 = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
				XCTFail("Did not get a v2 convo")
				return
			}
		}
	}

	func testCanInitiateV2Conversation() async throws {
		let existingConversations = try await aliceClient.conversations.list()
		XCTAssert(existingConversations.isEmpty, "already had conversations somehow")

		guard case let .v2(conversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
			XCTFail("Did not get a v2 convo")
			return
		}

		let aliceInviteMessage = fakeApiClient.findPublishedEnvelope(.userInvite(alice.walletAddress))
		let bobInviteMessage = fakeApiClient.findPublishedEnvelope(.userInvite(bob.walletAddress))

		XCTAssert(aliceInviteMessage != nil, "no alice invite message")
		XCTAssert(bobInviteMessage != nil, "no bob invite message")

		XCTAssertEqual(conversation.peerAddress, alice.walletAddress)

		let newConversations = try await aliceClient.conversations.list()
		XCTAssertEqual(1, newConversations.count, "already had conversations somehow")
	}

	func testCanFindExistingV1Conversation() async throws {
		let encoder = TextCodec()
		let encodedContent = try encoder.encode(content: "hi alice")

		// Get a date that's roughly two weeks ago to test with
		let someTimeAgo = Date().advanced(by: -2_000_000)

		let messageV1 = try MessageV1.encode(
			sender: bobClient.privateKeyBundleV1,
			recipient: aliceClient.privateKeyBundleV1.toPublicKeyBundle(),
			message: try encodedContent.serializedData(),
			timestamp: someTimeAgo
		)

		// Overwrite contact as legacy
		try await bobClient.publishUserContact(legacy: true)
		try await aliceClient.publishUserContact(legacy: true)

		try await bobClient.publish(envelopes: [
			Envelope(topic: .userIntro(bob.walletAddress), timestamp: someTimeAgo, message: try Message(v1: messageV1).serializedData()),
			Envelope(topic: .userIntro(alice.walletAddress), timestamp: someTimeAgo, message: try Message(v1: messageV1).serializedData()),
			Envelope(topic: .directMessageV1(bob.walletAddress, alice.walletAddress), timestamp: someTimeAgo, message: try Message(v1: messageV1).serializedData()),
		])

		guard case let .v1(conversation) = try await aliceClient.conversations.newConversation(with: bob.walletAddress) else {
			XCTFail("Did not have a convo with bob")
			return
		}

		XCTAssertEqual(conversation.peerAddress, bob.walletAddress)
		XCTAssertEqual(Int(conversation.sentAt.timeIntervalSince1970), Int(someTimeAgo.timeIntervalSince1970))

		let existingMessages = fakeApiClient.published.count

		guard case let .v1(conversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress) else {
			XCTFail("Did not have a convo with alice")
			return
		}

		XCTAssertEqual(existingMessages, fakeApiClient.published.count, "published more messages when we shouldn't have")
		XCTAssertEqual(conversation.peerAddress, alice.walletAddress)
		XCTAssertEqual(Int(conversation.sentAt.timeIntervalSince1970), Int(someTimeAgo.timeIntervalSince1970))
	}

	func testCanFindExistingV2Conversation() async throws {
		guard case let .v2(existingConversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress, context: .init(conversationID: "http://example.com/2")) else {
			XCTFail("Did not create existing conversation with alice")
			return
		}

		try await fakeApiClient.assertNoPublish {
			guard case let .v2(conversation) = try await bobClient.conversations.newConversation(with: alice.walletAddress, context: .init(conversationID: "http://example.com/2")) else {
				XCTFail("Did not get conversation with bob")
				return
			}

			XCTAssertEqual(conversation.topic, existingConversation.topic, "made new conversation instead of using existing one")
		}
	}

	func publishLegacyContact(client: Client) async throws {
		var contactBundle = ContactBundle()
		contactBundle.v1.keyBundle = client.privateKeyBundleV1.toPublicKeyBundle()

		var envelope = Envelope()
		envelope.contentTopic = Topic.contact(client.address).description
		envelope.timestampNs = UInt64(Date().millisecondsSinceEpoch * 1_000_000)
		envelope.message = try contactBundle.serializedData()

		try await client.publish(envelopes: [envelope])
	}

	func testStreamingMessagesFromV1Conversation() async throws {
		// Overwrite contact as legacy
		try await publishLegacyContact(client: bobClient)
		try await publishLegacyContact(client: aliceClient)

		guard case let .v1(conversation) = try await aliceClient.conversations.newConversation(with: bob.walletAddress) else {
			XCTFail("Did not have a convo with bob")
			return
		}

		let expectation = expectation(description: "got a message")

		Task(priority: .userInitiated) {
			for try await _ in conversation.streamMessages() {
				expectation.fulfill()
			}
		}

		let encoder = TextCodec()
		let encodedContent = try encoder.encode(content: "hi alice")

		let date = Date().advanced(by: -1_000_000)

		// Stream a message
		fakeApiClient.send(
			envelope: Envelope(
				topic: conversation.topic,
				timestamp: Date(),
				message: try Message(
					v1: MessageV1.encode(
						sender: bobClient.privateKeyBundleV1,
						recipient: aliceClient.privateKeyBundleV1.toPublicKeyBundle(),
						message: try encodedContent.serializedData(),
						timestamp: date
					)
				).serializedData()
			)
		)

		await waitForExpectations(timeout: 3)
	}

	func testStreamingMessagesFromV2Conversations() async throws {
		guard case let .v2(conversation) = try await aliceClient.conversations.newConversation(with: bob.walletAddress) else {
			XCTFail("Did not get a v2 convo")
			return
		}

		let expectation = expectation(description: "got a message")

		Task(priority: .userInitiated) {
			for try await _ in conversation.streamMessages() {
				expectation.fulfill()
			}
		}

		let encoder = TextCodec()
		let encodedContent = try encoder.encode(content: "hi alice")

		// Stream a message
		fakeApiClient.send(
			envelope: Envelope(
				topic: conversation.topic,
				timestamp: Date(),
				message: try Message(
					v2: try await MessageV2.encode(
						client: bobClient,
						content: encodedContent,
						topic: conversation.topic,
						keyMaterial: conversation.keyMaterial
					)
				).serializedData()
			)
		)

		await waitForExpectations(timeout: 3)
	}

	func testCanLoadV1Messages() async throws {
		// Overwrite contact as legacy so we can get v1
		try await publishLegacyContact(client: bobClient)
		try await publishLegacyContact(client: aliceClient)

		guard case let .v1(bobConversation) = try await bobClient.conversations.newConversation(with: alice.address) else {
			XCTFail("did not get a v1 conversation for alice")
			return
		}

		guard case let .v1(aliceConversation) = try await aliceClient.conversations.newConversation(with: bob.address) else {
			XCTFail("did not get a v1 conversation for alice")
			return
		}

		try await bobConversation.send(content: "hey alice")
		try await bobConversation.send(content: "hey alice again")

		let messages = try await aliceConversation.messages()

		XCTAssertEqual(2, messages.count)
		XCTAssertEqual("hey alice", messages[1].body)
		XCTAssertEqual(bob.address, messages[1].senderAddress)
	}

	func testCanLoadV2Messages() async throws {
		guard case let .v2(bobConversation) = try await bobClient.conversations.newConversation(with: alice.address, context: InvitationV1.Context(conversationID: "hi")) else {
			XCTFail("did not get a v2 conversation for alice")
			return
		}

		guard case let .v2(aliceConversation) = try await aliceClient.conversations.newConversation(with: bob.address, context: InvitationV1.Context(conversationID: "hi")) else {
			XCTFail("did not get a v2 conversation for alice")
			return
		}

		try await bobConversation.send(content: "hey alice")
		let messages = try await aliceConversation.messages()

		XCTAssertEqual(1, messages.count)
		XCTAssertEqual("hey alice", messages[0].body)
		XCTAssertEqual(bob.address, messages[0].senderAddress)
	}

	func testCanPaginateV1Messages() async throws {
		// Overwrite contact as legacy so we can get v1
		try await publishLegacyContact(client: bobClient)
		try await publishLegacyContact(client: aliceClient)

		guard case let .v1(bobConversation) = try await bobClient.conversations.newConversation(with: alice.address) else {
			XCTFail("did not get a v1 conversation for alice")
			return
		}

		guard case let .v1(aliceConversation) = try await aliceClient.conversations.newConversation(with: bob.address) else {
			XCTFail("did not get a v1 conversation for alice")
			return
		}

		try await bobConversation.send(content: "hey alice 1", sentAt: Date().addingTimeInterval(-10))
		try await bobConversation.send(content: "hey alice 2", sentAt: Date().addingTimeInterval(-5))
		try await bobConversation.send(content: "hey alice 3", sentAt: Date())

		let messages = try await aliceConversation.messages(limit: 1)
		XCTAssertEqual(1, messages.count)
		XCTAssertEqual("hey alice 3", messages[0].body)

		let messages2 = try await aliceConversation.messages(limit: 1, before: messages[0].sent)
		XCTAssertEqual(1, messages2.count)
		XCTAssertEqual("hey alice 2", messages2[0].body)
	}

	func testCanPaginateV2Messages() async throws {
		guard case let .v2(bobConversation) = try await bobClient.conversations.newConversation(with: alice.address, context: InvitationV1.Context(conversationID: "hi")) else {
			XCTFail("did not get a v2 conversation for alice")
			return
		}

		guard case let .v2(aliceConversation) = try await aliceClient.conversations.newConversation(with: bob.address, context: InvitationV1.Context(conversationID: "hi")) else {
			XCTFail("did not get a v2 conversation for alice")
			return
		}

		try await bobConversation.send(content: "hey alice 1", sentAt: Date().addingTimeInterval(-10))
		try await bobConversation.send(content: "hey alice 2", sentAt: Date().addingTimeInterval(-5))
		try await bobConversation.send(content: "hey alice 3", sentAt: Date())

		let messages = try await aliceConversation.messages(limit: 1)
		XCTAssertEqual(1, messages.count)
		XCTAssertEqual("hey alice 3", messages[0].body)

		let messages2 = try await aliceConversation.messages(limit: 1, before: messages[0].sent)
		XCTAssertEqual(1, messages2.count)
		XCTAssertEqual("hey alice 2", messages2[0].body)
	}
}
