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
        let fixtures = await fixtures()
        
        // Creation of all known types of topics
        let privateStore = Topic.userPrivateStoreKeyBundle(validId).description
        let contact = Topic.contact(validId).description
        let userIntro = Topic.userIntro(validId).description
        let userInvite = Topic.userInvite(validId).description
        let directMessageV1 = Topic.directMessageV1(validId, "sd").description
        let directMessageV2 = Topic.directMessageV2(validId).description
        let preferenceList = Topic.preferenceList(validId).description
        
        // check if validation of topics accepts all types
        Task(priority: .userInitiated) {
            let resultPrivateStore = Topic.isValidTopic(topic: privateStore)
            let resultContact = Topic.isValidTopic(topic: contact)
            let resultUserIntro = Topic.isValidTopic(topic: userIntro)
            let resultUserInvite = Topic.isValidTopic(topic: userInvite)
            let resultDirectMessageV1 = Topic.isValidTopic(topic: directMessageV1)
            let resultDirectMessageV2 = Topic.isValidTopic(topic: directMessageV2)
            let resultPreferenceList = Topic.isValidTopic(topic: preferenceList)
            XCTAssertTrue(
                resultPrivateStore && resultContact && resultUserIntro && resultUserInvite &&
                resultDirectMessageV1 && resultDirectMessageV2 && resultPreferenceList
            )
        }
    }
    
    func testCannotValidateTopicsInsideConversation() async throws {
        let invalidId = "��\\u0005�!\\u000b���5\\u00001\\u0007�蛨\\u001f\\u00172��.����K9K`�"
        let fixtures = await fixtures()
        
        // Creation of all known types of topics
        let privateStore = Topic.userPrivateStoreKeyBundle(invalidId).description
        let contact = Topic.contact(invalidId).description
        let userIntro = Topic.userIntro(invalidId).description
        let userInvite = Topic.userInvite(invalidId).description
        let directMessageV1 = Topic.directMessageV1(invalidId, "sd").description
        let directMessageV2 = Topic.directMessageV2(invalidId).description
        let preferenceList = Topic.preferenceList(invalidId).description
        
        // check if validation of topics declines all types
        Task(priority: .userInitiated) {
            let resultPrivateStore = Topic.isValidTopic(topic: privateStore)
            let resultContact = Topic.isValidTopic(topic: contact)
            let resultUserIntro = Topic.isValidTopic(topic: userIntro)
            let resultUserInvite = Topic.isValidTopic(topic: userInvite)
            let resultDirectMessageV1 = Topic.isValidTopic(topic: directMessageV1)
            let resultDirectMessageV2 = Topic.isValidTopic(topic: directMessageV2)
            let resultPreferenceList = Topic.isValidTopic(topic: preferenceList)
            XCTAssertFalse(
                resultPrivateStore && resultContact && resultUserIntro && resultUserInvite &&
                resultDirectMessageV1 && resultDirectMessageV2 && resultPreferenceList
            )
        }
    }
}
