//
//  GroupTests.swift
//
//
//  Created by Pat Nakajima on 2/1/24.
//

import CryptoKit
import XCTest
@testable import XMTPiOS
import LibXMTP
import XMTPTestHelpers

func assertThrowsAsyncError<T>(
		_ expression: @autoclosure () async throws -> T,
		_ message: @autoclosure () -> String = "",
		file: StaticString = #filePath,
		line: UInt = #line,
		_ errorHandler: (_ error: Error) -> Void = { _ in }
) async {
		do {
				_ = try await expression()
				// expected error to be thrown, but it was not
				let customMessage = message()
				if customMessage.isEmpty {
						XCTFail("Asynchronous call did not throw an error.", file: file, line: line)
				} else {
						XCTFail(customMessage, file: file, line: line)
				}
		} catch {
				errorHandler(error)
		}
}

@available(iOS 16, *)
class GroupTests: XCTestCase {
	// Use these fixtures to talk to the local node
	struct LocalFixtures {
		var alice: PrivateKey!
		var bob: PrivateKey!
		var fred: PrivateKey!
		var aliceClient: Client!
		var bobClient: Client!
		var fredClient: Client!
	}

	func localFixtures() async throws -> LocalFixtures {
		let key = try Crypto.secureRandomBytes(count: 32)
		let alice = try PrivateKey.generate()
		let aliceClient = try await Client.create(
			account: alice,
			options: .init(
				api: .init(env: .local, isSecure: false),
				codecs: [GroupUpdatedCodec()],
				enableV3: true,
				encryptionKey: key
			)
		)
		let bob = try PrivateKey.generate()
		let bobClient = try await Client.create(
			account: bob,
			options: .init(
				api: .init(env: .local, isSecure: false),
				codecs: [GroupUpdatedCodec()],
				enableV3: true,
				encryptionKey: key
			)
		)
		let fred = try PrivateKey.generate()
		let fredClient = try await Client.create(
			account: fred,
			options: .init(
				api: .init(env: .local, isSecure: false),
				codecs: [GroupUpdatedCodec()],
				enableV3: true,
				encryptionKey: key
			)
		)

		return .init(
			alice: alice,
			bob: bob,
			fred: fred,
			aliceClient: aliceClient,
			bobClient: bobClient,
			fredClient: fredClient
		)
	}

	func testCanCreateAGroupWithDefaultPermissions() async throws {
		let fixtures = try await localFixtures()
		let bobGroup = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await fixtures.aliceClient.conversations.sync()
		let aliceGroup = try await fixtures.aliceClient.conversations.groups().first!
		XCTAssert(!bobGroup.id.isEmpty)
		XCTAssert(!aliceGroup.id.isEmpty)
		
		try await aliceGroup.addMembers(addresses: [fixtures.fred.address])
		try await bobGroup.sync()

		XCTAssertEqual(try aliceGroup.members.count, 3)
		XCTAssertEqual(try bobGroup.members.count, 3)
        
        try await bobGroup.addAdmin(inboxId: fixtures.aliceClient.inboxID)

		try await aliceGroup.removeMembers(addresses: [fixtures.fred.address])
		try await bobGroup.sync()

        XCTAssertEqual(try aliceGroup.members.count, 2)
		XCTAssertEqual(try bobGroup.members.count, 2)

		try await bobGroup.addMembers(addresses: [fixtures.fred.address])
		try await aliceGroup.sync()
        
        try await bobGroup.removeAdmin(inboxId: fixtures.aliceClient.inboxID)
        try await aliceGroup.sync()

		XCTAssertEqual(try aliceGroup.members.count, 3)
		XCTAssertEqual(try bobGroup.members.count, 3)
		
		XCTAssertEqual(try bobGroup.permissionLevel(), .allMembers)
		XCTAssertEqual(try aliceGroup.permissionLevel(), .allMembers)

        XCTAssert(try bobGroup.isAdmin(inboxId: fixtures.bobClient.inboxID))
        XCTAssert(try !bobGroup.isAdmin(inboxId: fixtures.aliceClient.inboxID))
        XCTAssert(try aliceGroup.isAdmin(inboxId: fixtures.bobClient.inboxID))
        XCTAssert(try !aliceGroup.isAdmin(inboxId: fixtures.aliceClient.inboxID))
		
	}

	func testCanCreateAGroupWithAdminPermissions() async throws {
		let fixtures = try await localFixtures()
		let bobGroup = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address], permissions: GroupPermissions.adminOnly)
		try await fixtures.aliceClient.conversations.sync()
		let aliceGroup = try await fixtures.aliceClient.conversations.groups().first!
		XCTAssert(!bobGroup.id.isEmpty)
		XCTAssert(!aliceGroup.id.isEmpty)

		let bobConsentResult = await fixtures.bobClient.contacts.consentList.groupState(groupId: bobGroup.id)
		XCTAssertEqual(bobConsentResult, ConsentState.allowed)

		let aliceConsentResult = await fixtures.aliceClient.contacts.consentList.groupState(groupId: aliceGroup.id)
		XCTAssertEqual(aliceConsentResult, ConsentState.unknown)

		try await bobGroup.addMembers(addresses: [fixtures.fred.address])
		try await aliceGroup.sync()

		XCTAssertEqual(try aliceGroup.members.count, 3)
		XCTAssertEqual(try bobGroup.members.count, 3)

		await assertThrowsAsyncError(
			try await aliceGroup.removeMembers(addresses: [fixtures.fred.address])
		)
		try await bobGroup.sync()

		XCTAssertEqual(try aliceGroup.members.count, 3)
		XCTAssertEqual(try bobGroup.members.count, 3)
		
		try await bobGroup.removeMembers(addresses: [fixtures.fred.address])
		try await aliceGroup.sync()

		XCTAssertEqual(try aliceGroup.members.count, 2)
		XCTAssertEqual(try bobGroup.members.count, 2)

		await assertThrowsAsyncError(
			try await aliceGroup.addMembers(addresses: [fixtures.fred.address])
		)
		try await bobGroup.sync()

		XCTAssertEqual(try aliceGroup.members.count, 2)
		XCTAssertEqual(try bobGroup.members.count, 2)
		
		XCTAssertEqual(try bobGroup.permissionLevel(), .adminOnly)
		XCTAssertEqual(try aliceGroup.permissionLevel(), .adminOnly)
        XCTAssert(try bobGroup.isAdmin(inboxId: fixtures.bobClient.inboxID))
        XCTAssert(try !bobGroup.isAdmin(inboxId: fixtures.aliceClient.inboxID))
        XCTAssert(try aliceGroup.isAdmin(inboxId: fixtures.bobClient.inboxID))
        XCTAssert(try !aliceGroup.isAdmin(inboxId: fixtures.aliceClient.inboxID))
	}

	func testCanListGroups() async throws {
		let fixtures = try await localFixtures()
		_ = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])

		let aliceGroupCount = try await fixtures.aliceClient.conversations.groups().count

		try await fixtures.bobClient.conversations.sync()
		let bobGroupCount = try await fixtures.bobClient.conversations.groups().count

		XCTAssertEqual(1, aliceGroupCount)
		XCTAssertEqual(1, bobGroupCount)
	}
	
	func testCanListGroupsAndConversations() async throws {
		let fixtures = try await localFixtures()
		_ = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])
		_ = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bob.address)

		let aliceGroupCount = try await fixtures.aliceClient.conversations.list(includeGroups: true).count

		try await fixtures.bobClient.conversations.sync()
		let bobGroupCount = try await fixtures.bobClient.conversations.list(includeGroups: true).count

		XCTAssertEqual(2, aliceGroupCount)
		XCTAssertEqual(2, bobGroupCount)
	}

	func testCanListGroupMembers() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])

		try await group.sync()
		let members = try group.members.map(\.inboxId).sorted()
		let peerMembers = try Conversation.group(group).peerAddresses.sorted()

		XCTAssertEqual([fixtures.bobClient.inboxID, fixtures.aliceClient.inboxID].sorted(), members)
		XCTAssertEqual([fixtures.bobClient.inboxID].sorted(), peerMembers)
	}

	func testCanAddGroupMembers() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])

		try await group.addMembers(addresses: [fixtures.fred.address])

		try await group.sync()
		let members = try group.members.map(\.inboxId).sorted()

		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
			fixtures.fredClient.inboxID
		].sorted(), members)

		let groupChangedMessage: GroupUpdated = try await group.messages().first!.content()
		XCTAssertEqual(groupChangedMessage.addedInboxes.map(\.inboxID), [fixtures.fredClient.inboxID])
	}
	
	func testCanAddGroupMembersByInboxId() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])

		try await group.addMembersByInboxId(inboxIds: [fixtures.fredClient.inboxID])

		try await group.sync()
		let members = try group.members.map(\.inboxId).sorted()

		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
			fixtures.fredClient.inboxID
		].sorted(), members)

		let groupChangedMessage: GroupUpdated = try await group.messages().first!.content()
		XCTAssertEqual(groupChangedMessage.addedInboxes.map(\.inboxID), [fixtures.fredClient.inboxID])
	}

	func testCanRemoveMembers() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address, fixtures.fred.address])

		try await group.sync()
		let members = try group.members.map(\.inboxId).sorted()

		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
			fixtures.fredClient.inboxID
		].sorted(), members)

		try await group.removeMembers(addresses: [fixtures.fred.address])

		try await group.sync()

		let newMembers = try group.members.map(\.inboxId).sorted()
		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
		].sorted(), newMembers)

		let groupChangedMessage: GroupUpdated = try await group.messages().first!.content()
		XCTAssertEqual(groupChangedMessage.removedInboxes.map(\.inboxID), [fixtures.fredClient.inboxID])
	}
	
	func testCanRemoveMembersByInboxId() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address, fixtures.fred.address])

		try await group.sync()
		let members = try group.members.map(\.inboxId).sorted()

		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
			fixtures.fredClient.inboxID
		].sorted(), members)

		try await group.removeMembersByInboxId(inboxIds: [fixtures.fredClient.inboxID])

		try await group.sync()

		let newMembers = try group.members.map(\.inboxId).sorted()
		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
		].sorted(), newMembers)

		let groupChangedMessage: GroupUpdated = try await group.messages().first!.content()
		XCTAssertEqual(groupChangedMessage.removedInboxes.map(\.inboxID), [fixtures.fredClient.inboxID])
	}
	
	func testCanMessage() async throws {
		let fixtures = try await localFixtures()
		let notOnNetwork = try PrivateKey.generate()
		let canMessage = try await fixtures.aliceClient.canMessageV3(address: fixtures.bobClient.address)
		let cannotMessage = try await fixtures.aliceClient.canMessageV3(addresses: [notOnNetwork.address, fixtures.bobClient.address])
		XCTAssert(canMessage)
		XCTAssert(!(cannotMessage[notOnNetwork.address.lowercased()] ?? true))
	}
	
	func testIsActive() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address, fixtures.fred.address])

		try await group.sync()
		let members = try group.members.map(\.inboxId).sorted()

		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
			fixtures.fredClient.inboxID
		].sorted(), members)
		
		try await fixtures.fredClient.conversations.sync()
		let fredGroup = try await fixtures.fredClient.conversations.groups().first
		try await fredGroup?.sync()

		var isAliceActive = try group.isActive()
		var isFredActive = try fredGroup!.isActive()
		
		XCTAssert(isAliceActive)
		XCTAssert(isFredActive)

		try await group.removeMembers(addresses: [fixtures.fred.address])

		try await group.sync()

		let newMembers = try group.members.map(\.inboxId).sorted()
		XCTAssertEqual([
			fixtures.bobClient.inboxID,
			fixtures.aliceClient.inboxID,
		].sorted(), newMembers)
		
		try await fredGroup?.sync()
		
		isAliceActive = try group.isActive()
		isFredActive = try fredGroup!.isActive()
		
		XCTAssert(isAliceActive)
		XCTAssert(!isFredActive)
	}

	func testAddedByAddress() async throws {
		// Create clients
		let fixtures = try await localFixtures()

		// Alice creates a group and adds Bob to the group
		_ = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])

		// Bob syncs groups - this will decrypt the Welcome and then
		// identify who added Bob to the group
		try await fixtures.bobClient.conversations.sync()
		
		// Check Bob's group for the added_by_address of the inviter
		let bobGroup = try await fixtures.bobClient.conversations.groups().first
		let aliceAddress = fixtures.aliceClient.inboxID
		let whoAddedBob = try bobGroup?.addedByInboxId()
		
		// Verify the welcome host_credential is equal to Amal's
		XCTAssertEqual(aliceAddress, whoAddedBob)
	}

	func testCannotStartGroupWithSelf() async throws {
		let fixtures = try await localFixtures()

		await assertThrowsAsyncError(
			try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.alice.address])
		)
	}

	func testCanStartEmptyGroup() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.aliceClient.conversations.newGroup(with: [])
		XCTAssert(!group.id.isEmpty)
	}

	func testCannotStartGroupWithNonRegisteredIdentity() async throws {
		let fixtures = try await localFixtures()

		let nonRegistered = try PrivateKey.generate()

		do {
			_ = try await fixtures.aliceClient.conversations.newGroup(with: [nonRegistered.address])

			XCTFail("did not throw error")
		} catch {
			if case let GroupError.memberNotRegistered(addresses) = error {
				XCTAssertEqual([nonRegistered.address.lowercased()], addresses.map { $0.lowercased() })
			} else {
				XCTFail("did not throw correct error")
			}
		}
	}

	func testGroupStartsWithAllowedState() async throws {
		let fixtures = try await localFixtures()
		let bobGroup = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.walletAddress])

		_ = try await bobGroup.send(content: "howdy")
		_ = try await bobGroup.send(content: "gm")
		try await bobGroup.sync()

		let isGroupAllowedResult = await fixtures.bobClient.contacts.isGroupAllowed(groupId: bobGroup.id)
		XCTAssertTrue(isGroupAllowedResult)

		let groupStateResult = await fixtures.bobClient.contacts.consentList.groupState(groupId: bobGroup.id)
		XCTAssertEqual(groupStateResult, ConsentState.allowed)
	}
	
	func testCanSendMessagesToGroup() async throws {
		let fixtures = try await localFixtures()
		let aliceGroup = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])
		let membershipChange = GroupUpdated()

		try await fixtures.bobClient.conversations.sync()
		let bobGroup = try await fixtures.bobClient.conversations.groups()[0]

		_ = try await aliceGroup.send(content: "sup gang original")
		let messageId = try await aliceGroup.send(content: "sup gang")
		_ = try await aliceGroup.send(content: membershipChange, options: SendOptions(contentType: ContentTypeGroupUpdated))

		try await aliceGroup.sync()
		let aliceGroupsCount = try await aliceGroup.messages().count
		XCTAssertEqual(3, aliceGroupsCount)
		let aliceMessage = try await aliceGroup.messages().first!

		try await bobGroup.sync()
		let bobGroupsCount = try await bobGroup.messages().count
		XCTAssertEqual(2, bobGroupsCount)
		let bobMessage = try await bobGroup.messages().first!

		XCTAssertEqual("sup gang", try aliceMessage.content())
		XCTAssertEqual(messageId, aliceMessage.id)
		XCTAssertEqual(.published, aliceMessage.deliveryStatus)
		XCTAssertEqual("sup gang", try bobMessage.content())
	}
	
	func testCanListGroupMessages() async throws {
		let fixtures = try await localFixtures()
		let aliceGroup = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])
		_ = try await aliceGroup.send(content: "howdy")
		_ = try await aliceGroup.send(content: "gm")

		var aliceMessagesCount = try await aliceGroup.messages().count
		var aliceMessagesUnpublishedCount = try await aliceGroup.messages(deliveryStatus: .unpublished).count
		var aliceMessagesPublishedCount = try await aliceGroup.messages(deliveryStatus: .published).count
		XCTAssertEqual(3, aliceMessagesCount)
		XCTAssertEqual(2, aliceMessagesUnpublishedCount)
		XCTAssertEqual(1, aliceMessagesPublishedCount)

		try await aliceGroup.sync()
		
		aliceMessagesCount = try await aliceGroup.messages().count
		aliceMessagesUnpublishedCount = try await aliceGroup.messages(deliveryStatus: .unpublished).count
		aliceMessagesPublishedCount = try await aliceGroup.messages(deliveryStatus: .published).count
		XCTAssertEqual(3, aliceMessagesCount)
		XCTAssertEqual(0, aliceMessagesUnpublishedCount)
		XCTAssertEqual(3, aliceMessagesPublishedCount)

		try await fixtures.bobClient.conversations.sync()
		let bobGroup = try await fixtures.bobClient.conversations.groups()[0]
		try await bobGroup.sync()
		
		var bobMessagesCount = try await bobGroup.messages().count
		var bobMessagesUnpublishedCount = try await bobGroup.messages(deliveryStatus: .unpublished).count
		var bobMessagesPublishedCount = try await bobGroup.messages(deliveryStatus: .published).count
		XCTAssertEqual(2, bobMessagesCount)
		XCTAssertEqual(0, bobMessagesUnpublishedCount)
		XCTAssertEqual(2, bobMessagesPublishedCount)

	}
	
	func testCanSendMessagesToGroupDecrypted() async throws {
		let fixtures = try await localFixtures()
		let aliceGroup = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])

		try await fixtures.bobClient.conversations.sync()
		let bobGroup = try await fixtures.bobClient.conversations.groups()[0]

		_ = try await aliceGroup.send(content: "sup gang original")
		_ = try await aliceGroup.send(content: "sup gang")

		try await aliceGroup.sync()
		let aliceGroupsCount = try await aliceGroup.decryptedMessages().count
		XCTAssertEqual(3, aliceGroupsCount)
		let aliceMessage = try await aliceGroup.decryptedMessages().first!

		try await bobGroup.sync()
		let bobGroupsCount = try await bobGroup.decryptedMessages().count
		XCTAssertEqual(2, bobGroupsCount)
		let bobMessage = try await bobGroup.decryptedMessages().first!

		XCTAssertEqual("sup gang", String(data: Data(aliceMessage.encodedContent.content), encoding: .utf8))
		XCTAssertEqual("sup gang", String(data: Data(bobMessage.encodedContent.content), encoding: .utf8))
	}
	
	func testCanStreamGroupMessages() async throws {
		let fixtures = try await localFixtures()
		let group = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		let membershipChange = GroupUpdated()
		let expectation1 = expectation(description: "got a message")
		expectation1.expectedFulfillmentCount = 1

		Task(priority: .userInitiated) {
			for try await _ in group.streamMessages() {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await group.send(content: membershipChange, options: SendOptions(contentType: ContentTypeGroupUpdated))

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamGroups() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = expectation(description: "got a group")

		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamGroups() {
				expectation1.fulfill()
			}
		}

		_ = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamGroupsAndConversationsWorksGroups() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = expectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2

		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamAll() {
				expectation1.fulfill()
			}
		}

		_ = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		_ = try await fixtures.bobClient.conversations.newConversation(with: fixtures.alice.address)

		await waitForExpectations(timeout: 3)
	}
	
	func testStreamGroupsAndAllMessages() async throws {
		let fixtures = try await localFixtures()
		
		let expectation1 = expectation(description: "got a group")
		let expectation2 = expectation(description: "got a message")


		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamGroups() {
				expectation1.fulfill()
			}
		}
		
		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamAllMessages(includeGroups: true) {
				expectation2.fulfill()
			}
		}

		let group = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await group.send(content: "hello")

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamAndUpdateNameWithoutForkingGroup() async throws {
		let fixtures = try await localFixtures()
		
		let expectation = expectation(description: "got a message")
		expectation.expectedFulfillmentCount = 5

		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.bobClient.conversations.streamAllGroupMessages(){
				expectation.fulfill()
			}
		}

		let alixGroup = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address])
		try await alixGroup.updateGroupName(groupName: "hello")
		try await alixGroup.send(content: "hello1")
		
		try await fixtures.bobClient.conversations.sync()

		let boGroups = try await fixtures.bobClient.conversations.groups()
		XCTAssertEqual(boGroups.count, 1, "bo should have 1 group")
		let boGroup = boGroups[0]
		try await boGroup.sync()
		
		let boMessages1 = try await boGroup.messages()
		XCTAssertEqual(boMessages1.count, 2, "should have 2 messages on first load received \(boMessages1.count)")
		
		try await boGroup.send(content: "hello2")
		try await boGroup.send(content: "hello3")
		try await alixGroup.sync()

		let alixMessages = try await alixGroup.messages()
		for message in alixMessages {
			print("message", message.encodedContent.type, message.encodedContent.type.typeID)
		}
		XCTAssertEqual(alixMessages.count, 5, "should have 5 messages on first load received \(alixMessages.count)")

		try await alixGroup.send(content: "hello4")
		try await boGroup.sync()

		let boMessages2 = try await boGroup.messages()
		for message in boMessages2 {
			print("message", message.encodedContent.type, message.encodedContent.type.typeID)
		}
		XCTAssertEqual(boMessages2.count, 5, "should have 5 messages on second load received \(boMessages2.count)")

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamAllMessages() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = expectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2
		let convo = try await fixtures.bobClient.conversations.newConversation(with: fixtures.alice.address)
		let group = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await fixtures.aliceClient.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamAllMessages(includeGroups: true) {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await convo.send(content: "hi")

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamAllDecryptedMessages() async throws {
		let fixtures = try await localFixtures()
		let membershipChange = GroupUpdated()

		let expectation1 = expectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2
		let convo = try await fixtures.bobClient.conversations.newConversation(with: fixtures.alice.address)
		let group = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await fixtures.aliceClient.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamAllDecryptedMessages(includeGroups: true) {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await group.send(content: membershipChange, options: SendOptions(contentType: ContentTypeGroupUpdated))
		_ = try await convo.send(content: "hi")

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamAllGroupMessages() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = expectation(description: "got a conversation")

		let group = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await fixtures.aliceClient.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamAllGroupMessages() {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")

		await waitForExpectations(timeout: 3)
	}
	
	func testCanStreamAllGroupDecryptedMessages() async throws {
		let fixtures = try await localFixtures()

		let expectation1 = expectation(description: "got a conversation")
		let group = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await fixtures.aliceClient.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in try await fixtures.aliceClient.conversations.streamAllGroupDecryptedMessages() {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")

		await waitForExpectations(timeout: 3)
	}
    
    func testCanUpdateGroupMetadata() async throws {
        let fixtures = try await localFixtures()
        let group = try await fixtures.aliceClient.conversations.newGroup(with: [fixtures.bob.address], name: "Start Name", imageUrlSquare: "starturl.com")
        
        var groupName = try group.groupName()
		var groupImageUrlSquare = try group.groupImageUrlSquare()
        
        XCTAssertEqual(groupName, "Start Name")
		XCTAssertEqual(groupImageUrlSquare, "starturl.com")


        try await group.updateGroupName(groupName: "Test Group Name 1")
		try await group.updateGroupImageUrlSquare(imageUrlSquare: "newurl.com")
        
        groupName = try group.groupName()
		groupImageUrlSquare = try group.groupImageUrlSquare()

        XCTAssertEqual(groupName, "Test Group Name 1")
		XCTAssertEqual(groupImageUrlSquare, "newurl.com")
		
        let bobConv = try await fixtures.bobClient.conversations.list(includeGroups: true)[0]
        let bobGroup: Group;
        switch bobConv {
            case .v1(_):
                XCTFail("failed converting conversation to group")
                return
            case .v2(_):
                XCTFail("failed converting conversation to group")
                return
            case .group(let group):
                bobGroup = group
        }
        groupName = try bobGroup.groupName()
        XCTAssertEqual(groupName, "Start Name")
        
        try await bobGroup.sync()
        groupName = try bobGroup.groupName()
		groupImageUrlSquare = try bobGroup.groupImageUrlSquare()
		
		XCTAssertEqual(groupImageUrlSquare, "newurl.com")
        XCTAssertEqual(groupName, "Test Group Name 1")
    }
	
	func testCanAllowAndDenyInboxId() async throws {
		let fixtures = try await localFixtures()

		let isAllowed = await fixtures.bobClient.contacts.isInboxAllowed(inboxId: fixtures.aliceClient.inboxID)
		let isDenied = await fixtures.bobClient.contacts.isInboxDenied(inboxId: fixtures.aliceClient.inboxID)
		XCTAssert(!isAllowed)
		XCTAssert(!isDenied)

		try await fixtures.bobClient.contacts.allowInboxes(inboxIds: [fixtures.aliceClient.inboxID])

		let isAllowed2 = await fixtures.bobClient.contacts.isInboxAllowed(inboxId: fixtures.aliceClient.inboxID)
		let isDenied2 = await fixtures.bobClient.contacts.isInboxDenied(inboxId: fixtures.aliceClient.inboxID)
		XCTAssert(isAllowed2)
		XCTAssert(!isDenied2)

		try await fixtures.bobClient.contacts.denyInboxes(inboxIds: [fixtures.aliceClient.inboxID])

		let isAllowed3 = await fixtures.bobClient.contacts.isInboxAllowed(inboxId: fixtures.aliceClient.inboxID)
		let isDenied3 = await fixtures.bobClient.contacts.isInboxDenied(inboxId: fixtures.aliceClient.inboxID)
		XCTAssert(!isAllowed3)
		XCTAssert(isDenied3)
	}
	
	func testCanFetchGroupById() async throws {
		let fixtures = try await localFixtures()

		let boGroup = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])
		try await fixtures.aliceClient.conversations.sync()
		let alixGroup = try fixtures.aliceClient.findGroup(groupId: boGroup.id)

		XCTAssertEqual(alixGroup?.id.toHex, boGroup.id.toHex)
	}

	func testCanFetchMessageById() async throws {
		let fixtures = try await localFixtures()

		let boGroup = try await fixtures.bobClient.conversations.newGroup(with: [fixtures.alice.address])

		let boMessageId = try await boGroup.send(content: "Hello")
		try await fixtures.aliceClient.conversations.sync()
		let alixGroup = try fixtures.aliceClient.findGroup(groupId: boGroup.id)
		try await alixGroup?.sync()
		let alixMessage = try fixtures.aliceClient.findMessage(messageId: Data(boMessageId.web3.bytesFromHex!))

		XCTAssertEqual(alixGroup?.id.toHex, boGroup.id.toHex)
	}
}
