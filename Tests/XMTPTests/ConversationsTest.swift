//
//  ConversationsTests.swift
//
//
//  Created by Pat on 2/16/23.
//

import Foundation
import XCTest
@testable import XMTPiOS
import XMTPTestHelpers
import CryptoKit

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
	
	func testReturnsAllHMACKeys() async throws {
		try TestConfig.skipIfNotRunningLocalNodeTests()

		let alix = try PrivateKey.generate()
		let opts = ClientOptions(api: ClientOptions.Api(env: .local, isSecure: false))
		let alixClient = try await Client.create(
			account: alix,
			options: opts
		)
		var conversations: [Conversation] = []
		for _ in 0..<5 {
			let account = try PrivateKey.generate()
			let client = try await Client.create(account: account, options: opts)
			do {
				let newConversation = try await alixClient.conversations.newConversation(
					with: client.address,
					context: InvitationV1.Context(conversationID: "hi")
				)
				conversations.append(newConversation)
			} catch {
				print("Error creating conversation: \(error)")
			}
		}
		
		let thirtyDayPeriodsSinceEpoch = Int(Date().timeIntervalSince1970) / (60 * 60 * 24 * 30)
		
		let hmacKeys = await alixClient.conversations.getHmacKeys()
		
		let topics = hmacKeys.hmacKeys.keys
		conversations.forEach { conversation in
			XCTAssertTrue(topics.contains(conversation.topic))
		}
		
		var topicHmacs: [String: Data] = [:]
		let headerBytes = try Crypto.secureRandomBytes(count: 10)
		
		for conversation in conversations {
			let topic = conversation.topic
			let payload = try? TextCodec().encode(content: "Hello, world!", client: alixClient)
			
			_ = try await MessageV2.encode(
				client: alixClient,
				content: payload!,
				topic: topic,
				keyMaterial: headerBytes,
				codec: TextCodec()
			)
			
			let keyMaterial = conversation.keyMaterial
			let info = "\(thirtyDayPeriodsSinceEpoch)-\(alixClient.address)"
			let key = try Crypto.deriveKey(secret: keyMaterial!, nonce: Data(), info: Data(info.utf8))
			let hmac = try Crypto.calculateMac(headerBytes, key)
			
			topicHmacs[topic] = hmac
		}
		
		for (topic, hmacData) in hmacKeys.hmacKeys {
			for (idx, hmacKeyThirtyDayPeriod) in hmacData.values.enumerated() {
				let valid = Crypto.verifyHmacSignature(
					key: SymmetricKey(data: hmacKeyThirtyDayPeriod.hmacKey),
					signature: topicHmacs[topic]!,
					message: headerBytes
				)

				XCTAssertTrue(valid == (idx == 1))
			}
		}
	}
    
    func testSendConversationWithConsentSignature() async throws {
        let fixtures = await fixtures()
        let bo = try PrivateKey.generate()
        let alix = try PrivateKey.generate()
    
        let boClient = try await Client.create(account: bo, apiClient: fixtures.fakeApiClient)
        let alixClient = try await Client.create(account: alix, apiClient: fixtures.fakeApiClient)

        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        let signatureText = Signature.consentProofText(peerAddress: boClient.address, timestamp: timestamp)
        let signature = try await alix.sign(message: signatureText)
        
        let hex = signature.rawData.toHex
        var consentProofPayload = ConsentProofPayload()
        consentProofPayload.signature = hex
        consentProofPayload.timestamp = timestamp
        consentProofPayload.payloadVersion = .consentProofPayloadVersion1
        let boConversation =
        try await boClient.conversations.newConversation(with: alixClient.address, context: nil, consentProofPayload: consentProofPayload)
        let alixConversations = try await
            alixClient.conversations.list()
        let alixConversation = alixConversations.first(where: { $0.topic == boConversation.topic })
        XCTAssertNotNil(alixConversation)
        let consentStatus = await alixClient.contacts.isAllowed(boClient.address)
        XCTAssertTrue(consentStatus)
    }

    func testNetworkConsentOverConsentProof() async throws {
        let fixtures = await fixtures()
        let bo = try PrivateKey.generate()
        let alix = try PrivateKey.generate()
    
        let boClient = try await Client.create(account: bo, apiClient: fixtures.fakeApiClient)
        let alixClient = try await Client.create(account: alix, apiClient: fixtures.fakeApiClient)

        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        let signatureText = Signature.consentProofText(peerAddress: boClient.address, timestamp: timestamp)
        let signature = try await alix.sign(message: signatureText)
        let hex = signature.rawData.toHex
        var consentProofPayload = ConsentProofPayload()
        consentProofPayload.signature = hex
        consentProofPayload.timestamp = timestamp
        consentProofPayload.payloadVersion = .consentProofPayloadVersion1
        let boConversation =
        try await boClient.conversations.newConversation(with: alixClient.address, context: nil, consentProofPayload: consentProofPayload)
        try await alixClient.contacts.deny(addresses: [boClient.address])
        let alixConversations = try await
            alixClient.conversations.list()
        let alixConversation = alixConversations.first(where: { $0.topic == boConversation.topic })
        XCTAssertNotNil(alixConversation)
        let isDenied = await alixClient.contacts.isDenied(boClient.address)
        XCTAssertTrue(isDenied)
    }
    
    func testConsentProofInvalidSignature() async throws {
        let fixtures = await fixtures()
        let bo = try PrivateKey.generate()
        let alix = try PrivateKey.generate()
    
        let boClient = try await Client.create(account: bo, apiClient: fixtures.fakeApiClient)
        let alixClient = try await Client.create(account: alix, apiClient: fixtures.fakeApiClient)

        let timestamp = UInt64(Date().timeIntervalSince1970 * 1000)
        let signatureText = Signature.consentProofText(peerAddress: boClient.address, timestamp: timestamp + 1)
        let signature = try await alix.sign(message:signatureText)
        let hex = signature.rawData.toHex
        var consentProofPayload = ConsentProofPayload()
        consentProofPayload.signature = hex
        consentProofPayload.timestamp = timestamp
        consentProofPayload.payloadVersion = .consentProofPayloadVersion1
        let boConversation =
        try await boClient.conversations.newConversation(with: alixClient.address, context: nil, consentProofPayload: consentProofPayload)
        let alixConversations = try await
            alixClient.conversations.list()
        let alixConversation = alixConversations.first(where: { $0.topic == boConversation.topic })
        XCTAssertNotNil(alixConversation)
        let isAllowed = await alixClient.contacts.isAllowed(boClient.address)
        XCTAssertFalse(isAllowed)
    }
    
    func testHardCode() async throws {
        let message = "XMTP : Grant inbox consent to sender\n\nCurrent Time: 1714785568964\nFrom Address: 0x83A5D283F5B8c4D2c1913EA971a3B7FD8473F446\n\nFor more info: https://xmtp.org/signatures/"
        let keyBundle =
          "CooDCsIBCNODs8vTMRIiCiAX1cOb/Fd9VVxByqoWpW/+5xXPUcVjGXFOlYfeAq+i/xqUAQjTg7PL0zESRgpECkCv4ioiERGdb6PjKdbevjb9Y2j/up2bRfxQ9BHMfP1Lhx+7EXm9/ilPY/apoc98NLTq70LonXxkzfTJd99p4LiDEAEaQwpBBG9pNdML2/SSlsEAaQvh6mhPSaxVIoKVQZrHXVXvv4nlV/uJbT6hUfh74i/zaSJGI/151gaz6NFIRh0/iIsHDxwSwgEIvdGzy9MxEiIKICi1CtsGZ7irJSqkGhMy1zyw0ICg6lbWQ9VlUhudGBlrGpQBCL3Rs8vTMRJGCkQKQOhzxhSnIDWZyCYkFJvhET4S5eT86n3hw5pjlftVvCycWsNfLmtDhD7lhGc3B1fiWAmyc1jifx0ZaXicbfE23/EQARpDCkEEZ8ppzlYqzw7WxVVPutJD88twhKjSOBCUUMq2O6UQIql8Gpb2NtpRtOhh9lhs1dSBK58R6in4xIICnNIwoS+wQg=="
        guard let keyBundleData = Data(base64Encoded: keyBundle),
              let bundle = try? PrivateKeyBundle(serializedData: keyBundleData)
        else {
            return
        }
        let opts = ClientOptions(api: ClientOptions.Api(env: .dev, isSecure: false))
        let alex = try await Client.from(bundle: bundle, options: opts)
        let timestamp = UInt64(1714785568964)
        let sig =
          "0xbb272200f471cd70b94570ff07daca1de8e663883c698adb191f6677e76bd47b02a44b9928c61260bf1520e214f362fe3b766d22a526512f2f7699340840bacd1b"
        var consentProofPayload = ConsentProofPayload()
        consentProofPayload.signature = sig
        consentProofPayload.timestamp = timestamp
        consentProofPayload.payloadVersion = .consentProofPayloadVersion1
        let peer = "0x83A5D283F5B8c4D2c1913EA971a3B7FD8473F446"
        try await alex.conversations.handleConsentProof(consentProof: consentProofPayload, peerAddress: peer)
        
    }
}
