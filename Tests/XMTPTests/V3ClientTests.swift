//
//  File.swift
//  
//
//  Created by Naomi Plasterer on 9/19/24.
//

import CryptoKit
import XCTest
@testable import XMTPiOS
import LibXMTP
import XMTPTestHelpers

@available(iOS 16, *)
class V3ClientTests: XCTestCase {
	// Use these fixtures to talk to the local node
	struct LocalFixtures {
		var alixV2: PrivateKey!
		var boV3: PrivateKey!
		var caroV2V3: PrivateKey!
		var alixV2Client: Client!
		var boV3Client: Client!
		var caroV2V3Client: Client!
	}
	
	func localFixtures() async throws -> LocalFixtures {
		let key = try Crypto.secureRandomBytes(count: 32)
		let alixV2 = try PrivateKey.generate()
		let alixV2Client = try await Client.create(
			account: alixV2,
			options: .init(
				api: .init(env: .local, isSecure: false)
			)
		)
		let boV3 = try PrivateKey.generate()
		let boV3Client = try await Client.createOrBuild(
			account: boV3,
			options: .init(
				api: .init(env: .local, isSecure: false),
				enableV3: true,
				encryptionKey: key
			)
		)
		let caroV2V3 = try PrivateKey.generate()
		let caroV2V3Client = try await Client.create(
			account: caroV2V3,
			options: .init(
				api: .init(env: .local, isSecure: false),
				enableV3: true,
				encryptionKey: key
			)
		)
		
		return .init(
			alixV2: alixV2,
			boV3: boV3,
			caroV2V3: caroV2V3,
			alixV2Client: alixV2Client,
			boV3Client: boV3Client,
			caroV2V3Client: caroV2V3Client
		)
	}
	
	func testsCanCreateGroup() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.boV3Client.conversations.newGroup(with: [fixtures.caroV2V3.address])
		let members = try await group.members.map(\.inboxId).sorted()
		XCTAssertEqual([fixtures.caroV2V3Client.inboxID, fixtures.boV3Client.inboxID].sorted(), members)

		await assertThrowsAsyncError(
			try await fixtures.boV3Client.conversations.newGroup(with: [fixtures.alixV2.address])
		)
	}
	
	func testsCanSendMessages() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.boV3Client.conversations.newGroup(with: [fixtures.caroV2V3.address])
		try await group.send(content: "howdy")
		let messageId = try await group.send(content: "gm")
		try await group.sync()
		
		let groupMessages = try await group.messages()
		XCTAssertEqual(groupMessages.first?.body, "gm")
		XCTAssertEqual(groupMessages.first?.id, messageId)
		XCTAssertEqual(groupMessages.first?.deliveryStatus, .published)
		XCTAssertEqual(groupMessages.count, 3)


		try await fixtures.caroV2V3Client.conversations.sync()
		let sameGroup = try await fixtures.caroV2V3Client.conversations.groups().last
		try await sameGroup?.sync()

		let sameGroupMessages = try await sameGroup?.messages()
		XCTAssertEqual(sameGroupMessages?.count, 2)
		XCTAssertEqual(sameGroupMessages?.first?.body, "gm")
	}
	
	func testCanStreamAllMessagesFromV2andV3Users() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = XCTestExpectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2
		let convo = try await fixtures.alixV2Client.conversations.newConversation(with: fixtures.caroV2V3.address)
		let group = try await fixtures.boV3Client.conversations.newGroup(with: [fixtures.caroV2V3.address])
		try await fixtures.caroV2V3Client.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in await fixtures.caroV2V3Client.conversations.streamAllMessages(includeGroups: true) {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await convo.send(content: "hi")

		await fulfillment(of: [expectation1], timeout: 3)
	}
	
	func testCanStreamGroupsAndConversationsFromV2andV3Users() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = XCTestExpectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.caroV2V3Client.conversations.streamAll() {
				expectation1.fulfill()
			}
		}

		_ = try await fixtures.boV3Client.conversations.newGroup(with: [fixtures.caroV2V3.address])
		_ = try await fixtures.alixV2Client.conversations.newConversation(with: fixtures.caroV2V3.address)

		await fulfillment(of: [expectation1], timeout: 3)
	}
}
