//
//  ConversationsTests.swift
//
//
//  Created by Pat on 2/16/23.
//

import Foundation
import XCTest
@testable import XMTP

@available(macOS 13.0, *)
@available(iOS 15, *)
class ConversationsTests: XCTestCase {
	func testCanGetConversationFromIntroEnvelope() async throws {
		let fixtures = await fixtures()
		let client = fixtures.aliceClient!

		let created = Date()
		let newWallet = try PrivateKey.generate()
		let newClient = try await Client.create(account: newWallet, apiClient: fixtures.fakeApiClient)

		let message = try MessageV1.encode(
			sender: newClient.privateKeyBundleV1,
			recipient: fixtures.aliceClient.v1keys.toPublicKeyBundle(),
			message: try TextCodec().encode(content: "hello", client: client).serializedData(),
			timestamp: created
		)

		let envelope = Envelope(topic: .userIntro(client.address), timestamp: created, message: try Message(v1: message).serializedData())

		let conversation = try await client.conversations.fromIntro(envelope: envelope)
		XCTAssertEqual(conversation.peerAddress, newWallet.address)
		XCTAssertEqual(conversation.createdAt.description, created.description)
	}

	func testCanGetConversationFromInviteEnvelope() async throws {
		let fixtures = await fixtures()
		let client: Client = fixtures.aliceClient!

		let created = Date()
		let newWallet = try PrivateKey.generate()
		let newClient = try await Client.create(account: newWallet, apiClient: fixtures.fakeApiClient)

		let invitation = try InvitationV1.createDeterministic(
				sender: newClient.keys,
				recipient: client.keys.getPublicKeyBundle())
		let sealed = try SealedInvitation.createV1(
			sender: newClient.keys,
			recipient: client.keys.getPublicKeyBundle(),
			created: created,
			invitation: invitation
		)

		let peerAddress = fixtures.alice.walletAddress
		let envelope = Envelope(topic: .userInvite(peerAddress), timestamp: created, message: try sealed.serializedData())

		let conversation = try await client.conversations.fromInvite(envelope: envelope)
		XCTAssertEqual(conversation.peerAddress, newWallet.address)
		XCTAssertEqual(conversation.createdAt.description, created.description)
	}

	func testStreamAllMessagesGetsMessageFromKnownConversation() async throws {
		let fixtures = await fixtures()
		let client = fixtures.aliceClient!

		let bobConversation = try await fixtures.bobClient.conversations.newConversation(with: client.address)

		let expectation1 = expectation(description: "got a message")

		Task(priority: .userInitiated) {
			for try await _ in try await client.conversations.streamAllMessages() {
				expectation1.fulfill()
			}
		}

		_ = try await bobConversation.send(text: "hi")

		await waitForExpectations(timeout: 3)
	}
    
    func testCanValidateTopicsInsideConversation() async throws {
        let validId = "sdfsadf095b97a9284dcd82b2274856ccac8a21de57bebe34e7f9eeb855fb21126d3b8f"
        
        // Creation of all known types of topics
        let privateStore = Topic.userPrivateStoreKeyBundle(validId).description
        let contact = Topic.contact(validId).description
        let userIntro = Topic.userIntro(validId).description
        let userInvite = Topic.userInvite(validId).description
        let directMessageV1 = Topic.directMessageV1(validId, "sd").description
        let directMessageV2 = Topic.directMessageV2(validId).description
        let preferenceList = Topic.preferenceList(validId).description
        
        // check if validation of topics accepts all types
        XCTAssertTrue(Topic.isValidTopic(topic: privateStore))
        XCTAssertTrue(Topic.isValidTopic(topic: contact))
        XCTAssertTrue(Topic.isValidTopic(topic: userIntro))
        XCTAssertTrue(Topic.isValidTopic(topic: userInvite))
        XCTAssertTrue(Topic.isValidTopic(topic: directMessageV1))
        XCTAssertTrue(Topic.isValidTopic(topic: directMessageV2))
        XCTAssertTrue(Topic.isValidTopic(topic: preferenceList))
    }
    
    func testCannotValidateTopicsInsideConversation() async throws {
        let invalidId = "��\\u0005�!\\u000b���5\\u00001\\u0007�蛨\\u001f\\u00172��.����K9K`�"
        
        // Creation of all known types of topics
        let privateStore = Topic.userPrivateStoreKeyBundle(invalidId).description
        let contact = Topic.contact(invalidId).description
        let userIntro = Topic.userIntro(invalidId).description
        let userInvite = Topic.userInvite(invalidId).description
        let directMessageV1 = Topic.directMessageV1(invalidId, "sd").description
        let directMessageV2 = Topic.directMessageV2(invalidId).description
        let preferenceList = Topic.preferenceList(invalidId).description
        
        // check if validation of topics declines all types
        XCTAssertFalse(Topic.isValidTopic(topic: privateStore))
        XCTAssertFalse(Topic.isValidTopic(topic: contact))
        XCTAssertFalse(Topic.isValidTopic(topic: userIntro))
        XCTAssertFalse(Topic.isValidTopic(topic: userInvite))
        XCTAssertFalse(Topic.isValidTopic(topic: directMessageV1))
        XCTAssertFalse(Topic.isValidTopic(topic: directMessageV2))
        XCTAssertFalse(Topic.isValidTopic(topic: preferenceList))
    }
	
	func testLoadConvos() async throws {
		// Data from hex: 0836200ffafa17a3cb8b54f22d6afa60b13da48726543241adc5c250dbb0e0cd
		// aka 2k many convo test wallet
		let privateKeyData = Data([8,54,32,15,250,250,23,163,203,139,84,242,45,106,250,96,177,61,164,135,38,84,50,65,173,197,194,80,219,176,224,205])
		let privateKey = try PrivateKey(privateKeyData)
		// Use hardcoded privateKey for testing
		let options = XMTP.ClientOptions(api: ClientOptions.Api(env: .dev, isSecure: true))
		let client = try await Client.create(account: privateKey, options: options)
		
		let start = Date()
		let conversations = try await client.conversations.list()
		let end = Date()
		print("Loaded \(conversations.count) conversations in \(end.timeIntervalSince(start))s")
		
		let start2 = Date()
		let conversations2 = try await client.conversations.list()
		let end2 = Date()
		print("Second time loaded \(conversations2.count) conversations in \(end2.timeIntervalSince(start2))s")

		let first500Topics = try conversations.prefix(500).map { try $0.toTopicData().serializedData() }
		let client2 = try await Client.create(account: privateKey, options: options)
		for topic in first500Topics {
			await client2.conversations.importTopicData(data: try Xmtp_KeystoreApi_V1_TopicMap.TopicData(serializedData: topic))
		}	
		let start3 = Date()
		let conversations3 = try await client2.conversations.list()
		let end3 = Date()
		print("Loaded \(conversations3.count) conversations in \(end3.timeIntervalSince(start3))s")
		
		let start4 = Date()
		let conversations4 = try await client2.conversations.list()
		let end4 = Date()
		print("Second time loaded \(conversations4.count) conversations in \(end4.timeIntervalSince(start4))s")
	}
}
