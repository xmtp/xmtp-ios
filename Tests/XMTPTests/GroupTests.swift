import LibXMTP
import XCTest
import XMTPTestHelpers

@testable import XMTPiOS

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
			XCTFail(
				"Asynchronous call did not throw an error.", file: file,
				line: line)
		} else {
			XCTFail(customMessage, file: file, line: line)
		}
	} catch {
		errorHandler(error)
	}
}

@available(iOS 16, *)
class GroupTests: XCTestCase {
	func testCanCreateAGroupWithDefaultPermissions() async throws {
		let fixtures = try await fixtures()
		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID])
		try await fixtures.alixClient.conversations.sync()
		let alixGroup = try await fixtures.alixClient.conversations
			.listGroups().first!
		XCTAssert(!boGroup.id.isEmpty)
		XCTAssert(!alixGroup.id.isEmpty)

		try await alixGroup.addMembers(inboxIds: [fixtures.caroClient.inboxID])
		try await boGroup.sync()

		var alixMembersCount = try await alixGroup.members.count
		var boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 3)
		XCTAssertEqual(boMembersCount, 3)

		try await boGroup.addAdmin(inboxId: fixtures.alixClient.inboxID)

		try await alixGroup.removeMembers(inboxIds: [
			fixtures.caroClient.inboxID
		])
		try await boGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 2)
		XCTAssertEqual(boMembersCount, 2)

		try await boGroup.addMembers(inboxIds: [fixtures.caroClient.inboxID])
		try await alixGroup.sync()

		try await boGroup.removeAdmin(inboxId: fixtures.alixClient.inboxID)
		try await alixGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 3)
		XCTAssertEqual(boMembersCount, 3)

		XCTAssertEqual(
			try boGroup.permissionPolicySet().addMemberPolicy, .allow)
		XCTAssertEqual(
			try alixGroup.permissionPolicySet().addMemberPolicy, .allow)

		XCTAssert(
			try boGroup.isSuperAdmin(inboxId: fixtures.boClient.inboxID))
		XCTAssert(
			try !boGroup.isSuperAdmin(inboxId: fixtures.alixClient.inboxID))
		XCTAssert(
			try alixGroup.isSuperAdmin(inboxId: fixtures.boClient.inboxID))
		XCTAssert(
			try !alixGroup.isSuperAdmin(inboxId: fixtures.alixClient.inboxID))
		try fixtures.cleanUpDatabases()
	}

	func testCanCreateAGroupWithIdentityDefaultPermissions() async throws {
		let fixtures = try await fixtures()
		let boGroup = try await fixtures.boClient.conversations
			.newGroupWithIdentities(
				with: [
					PublicIdentity(
						kind: .ethereum, identifier: fixtures.alix.walletAddress
					)
				])
		try await fixtures.alixClient.conversations.sync()
		let alixGroup = try await fixtures.alixClient.conversations
			.listGroups().first!
		XCTAssert(!boGroup.id.isEmpty)
		XCTAssert(!alixGroup.id.isEmpty)

		try await alixGroup.addMembers(inboxIds: [fixtures.caroClient.inboxID])
		try await boGroup.sync()

		var alixMembersCount = try await alixGroup.members.count
		var boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 3)
		XCTAssertEqual(boMembersCount, 3)

		try await boGroup.addAdmin(inboxId: fixtures.alixClient.inboxID)

		try await alixGroup.removeMembers(inboxIds: [
			fixtures.caroClient.inboxID
		])
		try await boGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 2)
		XCTAssertEqual(boMembersCount, 2)

		try await boGroup.addMembers(inboxIds: [fixtures.caroClient.inboxID])
		try await alixGroup.sync()

		try await boGroup.removeAdmin(inboxId: fixtures.alixClient.inboxID)
		try await alixGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 3)
		XCTAssertEqual(boMembersCount, 3)

		XCTAssertEqual(
			try boGroup.permissionPolicySet().addMemberPolicy, .allow)
		XCTAssertEqual(
			try alixGroup.permissionPolicySet().addMemberPolicy, .allow)

		XCTAssert(
			try boGroup.isSuperAdmin(inboxId: fixtures.boClient.inboxID))
		XCTAssert(
			try !boGroup.isSuperAdmin(inboxId: fixtures.alixClient.inboxID))
		XCTAssert(
			try alixGroup.isSuperAdmin(inboxId: fixtures.boClient.inboxID))
		XCTAssert(
			try !alixGroup.isSuperAdmin(inboxId: fixtures.alixClient.inboxID))
		try fixtures.cleanUpDatabases()
	}

	func testCanCreateAGroupWithAdminPermissions() async throws {
		let fixtures = try await fixtures()
		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID],
			permissions: GroupPermissionPreconfiguration.adminOnly)
		try await fixtures.alixClient.conversations.sync()
		let alixGroup = try await fixtures.alixClient.conversations
			.listGroups().first!
		XCTAssert(!boGroup.id.isEmpty)
		XCTAssert(!alixGroup.id.isEmpty)

		let boConsentResult = try boGroup.consentState()
		XCTAssertEqual(boConsentResult, ConsentState.allowed)

		let alixConsentResult = try await fixtures.alixClient.preferences
			.conversationState(conversationId: alixGroup.id)
		XCTAssertEqual(alixConsentResult, ConsentState.unknown)

		try await boGroup.addMembers(inboxIds: [fixtures.caroClient.inboxID])
		try await alixGroup.sync()

		var alixMembersCount = try await alixGroup.members.count
		var boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 3)
		XCTAssertEqual(boMembersCount, 3)

		await assertThrowsAsyncError(
			try await alixGroup.removeMembers(inboxIds: [
				fixtures.caroClient.inboxID
			])
		)
		try await boGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 3)
		XCTAssertEqual(boMembersCount, 3)

		try await boGroup.removeMembers(inboxIds: [fixtures.caroClient.inboxID])
		try await alixGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 2)
		XCTAssertEqual(boMembersCount, 2)

		await assertThrowsAsyncError(
			try await alixGroup.addMembers(inboxIds: [
				fixtures.caroClient.inboxID
			])
		)
		try await boGroup.sync()

		alixMembersCount = try await alixGroup.members.count
		boMembersCount = try await boGroup.members.count
		XCTAssertEqual(alixMembersCount, 2)
		XCTAssertEqual(boMembersCount, 2)

		XCTAssertEqual(
			try boGroup.permissionPolicySet().addMemberPolicy, .admin)
		XCTAssertEqual(
			try alixGroup.permissionPolicySet().addMemberPolicy, .admin)
		XCTAssert(
			try boGroup.isSuperAdmin(inboxId: fixtures.boClient.inboxID))
		XCTAssert(
			try !boGroup.isSuperAdmin(inboxId: fixtures.alixClient.inboxID))
		XCTAssert(
			try alixGroup.isSuperAdmin(inboxId: fixtures.boClient.inboxID))
		XCTAssert(
			try !alixGroup.isSuperAdmin(inboxId: fixtures.alixClient.inboxID))
		try fixtures.cleanUpDatabases()
	}

	func testCanListGroups() async throws {
		let fixtures = try await fixtures()
		_ = try await fixtures.alixClient.conversations.newGroup(with: [
			fixtures.boClient.inboxID
		])
		_ = try await fixtures.caroClient.conversations.findOrCreateDm(
			with: fixtures.boClient.inboxID)
		_ = try await fixtures.caroClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)

		try await fixtures.alixClient.conversations.sync()
		let alixGroupCount = try await fixtures.alixClient.conversations
			.listGroups().count

		try await fixtures.boClient.conversations.sync()
		let boGroupCount = try await fixtures.boClient.conversations
			.listGroups().count

		XCTAssertEqual(1, alixGroupCount)
		XCTAssertEqual(1, boGroupCount)
		try fixtures.cleanUpDatabases()
	}

	func testCanListGroupsFiltered() async throws {
		let fixtures = try await fixtures()

		let _ = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caroClient.inboxID)
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caroClient.inboxID
		])
		let _ = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caroClient.inboxID
		])

		let convoCount = try await fixtures.boClient.conversations
			.listGroups().count
		let convoCountConsent = try await fixtures.boClient.conversations
			.listGroups(consentStates: [.allowed]).count

		XCTAssertEqual(convoCount, 2)
		XCTAssertEqual(convoCountConsent, 2)

		try await group.updateConsentState(state: .denied)

		let convoCountAllowed = try await fixtures.boClient.conversations
			.listGroups(consentStates: [.allowed]).count
		let convoCountDenied = try await fixtures.boClient.conversations
			.listGroups(consentStates: [.denied]).count
		let convoCountCombined = try await fixtures.boClient.conversations
			.listGroups(consentStates: [.denied, .allowed]).count

		XCTAssertEqual(convoCountAllowed, 1)
		XCTAssertEqual(convoCountDenied, 1)
		XCTAssertEqual(convoCountCombined, 2)
		try fixtures.cleanUpDatabases()
	}

	func testCanListGroupsOrder() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caroClient.inboxID)
		let group1 = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.caroClient.inboxID])
		let group2 = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.caroClient.inboxID])

		_ = try await dm.send(content: "Howdy")
		_ = try await group2.send(content: "Howdy")
		_ = try await fixtures.boClient.conversations.syncAllConversations()

		let conversations = try await fixtures.boClient.conversations
			.listGroups()

		XCTAssertEqual(conversations.count, 2)
		XCTAssertEqual(
			conversations.map { $0.id }, [group2.id, group1.id])
		try fixtures.cleanUpDatabases()
	}

	func testCanListGroupMembers() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID])

		try await group.sync()
		let members = try await group.members.map(\.inboxId).sorted()
		let peerMembers = try await group.peerInboxIds.sorted()

		XCTAssertEqual(
			[fixtures.boClient.inboxID, fixtures.alixClient.inboxID].sorted(),
			members)
		XCTAssertEqual([fixtures.boClient.inboxID].sorted(), peerMembers)
		try fixtures.cleanUpDatabases()
	}

	func testCanAddGroupMembers() async throws {
		let fixtures = try await fixtures()
		Client.register(codec: GroupUpdatedCodec())
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID])

		let result = try await group.addMembers(inboxIds: [fixtures.caroClient.inboxID])

		XCTAssertEqual(result.addedMembers.first, fixtures.caroClient.inboxID)

		try await group.sync()
		let members = try await group.members.map(\.inboxId).sorted()

		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
				fixtures.caroClient.inboxID,
			].sorted(), members)

		let groupChangedMessage: GroupUpdated = try await group.messages()
			.first!.content()
		XCTAssertEqual(
			groupChangedMessage.addedInboxes.map(\.inboxID),
			[fixtures.caroClient.inboxID])
		try fixtures.cleanUpDatabases()
	}
	
	func testCannotStartGroupOrAddMembersWithAddressWhenExpectingInboxId() async throws {
		let fixtures = try await fixtures()

		do {
			_ = try await fixtures.boClient.conversations.newGroup(with: [fixtures.alix.walletAddress])
			XCTFail("Did not throw error")
		} catch {
			if case let ClientError.invalidInboxId(message) = error {
				XCTAssertEqual(message.lowercased(), fixtures.alix.walletAddress.lowercased())
			} else {
				XCTFail("Did not throw correct error")
			}
		}

		let group = try await fixtures.boClient.conversations.newGroup(with: [fixtures.alixClient.inboxID])

		do {
			_ = try await group.addMembers(inboxIds: [fixtures.caro.walletAddress])
			XCTFail("Did not throw error")
		} catch {
			if case let ClientError.invalidInboxId(message) = error {
				XCTAssertEqual(message.lowercased(), fixtures.caro.walletAddress.lowercased())
			} else {
				XCTFail("Did not throw correct error")
			}
		}

		do {
			_ = try await group.removeMembers(inboxIds: [fixtures.alix.walletAddress])
			XCTFail("Did not throw error")
		} catch {
			if case let ClientError.invalidInboxId(message) = error {
				XCTAssertEqual(message.lowercased(), fixtures.alix.walletAddress.lowercased())
			} else {
				XCTFail("Did not throw correct error")
			}
		}
		try fixtures.cleanUpDatabases()
	}

	func testCanAddGroupMembersByIdentity() async throws {
		let fixtures = try await fixtures()
		Client.register(codec: GroupUpdatedCodec())
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID])

		let result = try await group.addMembersByIdentity(identities: [
			PublicIdentity(
				kind: .ethereum, identifier: fixtures.caro.walletAddress)
		])
		
		XCTAssertEqual(result.addedMembers.first, fixtures.caroClient.inboxID)

		try await group.sync()
		let members = try await group.members.map(\.inboxId).sorted()

		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
				fixtures.caroClient.inboxID,
			].sorted(), members)

		let groupChangedMessage: GroupUpdated = try await group.messages()
			.first!.content()
		XCTAssertEqual(
			groupChangedMessage.addedInboxes.map(\.inboxID),
			[fixtures.caroClient.inboxID])
		try fixtures.cleanUpDatabases()
	}

	func testCanRemoveMembers() async throws {
		let fixtures = try await fixtures()
		Client.register(codec: GroupUpdatedCodec())
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID, fixtures.caroClient.inboxID])

		try await group.sync()
		let members = try await group.members.map(\.inboxId).sorted()

		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
				fixtures.caroClient.inboxID,
			].sorted(), members)

		try await group.removeMembers(inboxIds: [fixtures.caroClient.inboxID])

		try await group.sync()

		let newMembers = try await group.members.map(\.inboxId).sorted()
		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
			].sorted(), newMembers)

		let groupChangedMessage: GroupUpdated = try await group.messages()
			.first!.content()
		XCTAssertEqual(
			groupChangedMessage.removedInboxes.map(\.inboxID),
			[fixtures.caroClient.inboxID])
		try fixtures.cleanUpDatabases()
	}

	func testCanRemoveMembersByIdentity() async throws {
		let fixtures = try await fixtures()
		Client.register(codec: GroupUpdatedCodec())
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID, fixtures.caroClient.inboxID])

		try await group.sync()
		let members = try await group.members.map(\.inboxId).sorted()

		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
				fixtures.caroClient.inboxID,
			].sorted(), members)

		try await group.removeMembersByIdentity(identities: [fixtures.caro.identity])

		try await group.sync()

		let newMembers = try await group.members.map(\.inboxId).sorted()
		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
			].sorted(), newMembers)

		let groupChangedMessage: GroupUpdated = try await group.messages()
			.first!.content()
		XCTAssertEqual(
			groupChangedMessage.removedInboxes.map(\.inboxID),
			[fixtures.caroClient.inboxID])
		try fixtures.cleanUpDatabases()
	}

	func testCanMessage() async throws {
		let fixtures = try await fixtures()
		let notOnNetwork = try PrivateKey.generate()
		let canMessage = try await fixtures.alixClient.canMessage(
			identity: fixtures.bo.identity)
		let cannotMessage = try await fixtures.alixClient.canMessage(
			identities: [
				PublicIdentity(
					kind: .ethereum, identifier: notOnNetwork.walletAddress),
				fixtures.bo.identity,
			])
		XCTAssert(canMessage)
		XCTAssert(
			!(cannotMessage[notOnNetwork.walletAddress.lowercased()] ?? true))
		try fixtures.cleanUpDatabases()
	}

	func testIsActive() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID, fixtures.caroClient.inboxID])

		try await group.sync()
		let members = try await group.members.map(\.inboxId).sorted()

		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
				fixtures.caroClient.inboxID,
			].sorted(), members)

		try await fixtures.caroClient.conversations.sync()
		let caroGroup = try await fixtures.caroClient.conversations.listGroups()
			.first
		try await caroGroup?.sync()

		var isalixActive = try group.isActive()
		var iscaroActive = try caroGroup!.isActive()

		XCTAssert(isalixActive)
		XCTAssert(iscaroActive)

		try await group.removeMembers(inboxIds: [fixtures.caroClient.inboxID])

		try await group.sync()

		let newMembers = try await group.members.map(\.inboxId).sorted()
		XCTAssertEqual(
			[
				fixtures.boClient.inboxID,
				fixtures.alixClient.inboxID,
			].sorted(), newMembers)

		try await caroGroup?.sync()

		isalixActive = try group.isActive()
		iscaroActive = try caroGroup!.isActive()

		XCTAssert(isalixActive)
		XCTAssert(!iscaroActive)
		try fixtures.cleanUpDatabases()
	}

	func testAddedByAddress() async throws {
		// Create clients
		let fixtures = try await fixtures()

		// alix creates a group and adds bo to the group
		_ = try await fixtures.alixClient.conversations.newGroup(with: [
			fixtures.boClient.inboxID
		])

		// bo syncs groups - this will decrypt the Welcome and then
		// identify who added bo to the group
		try await fixtures.boClient.conversations.sync()

		// Check bo's group for the added_by_address of the inviter
		let boGroup = try await fixtures.boClient.conversations.listGroups()
			.first
		let alixAddress = fixtures.alixClient.inboxID
		let whoAddedbo = try boGroup?.addedByInboxId()

		// Verify the welcome host_credential is equal to Amal's
		XCTAssertEqual(alixAddress, whoAddedbo)
		try fixtures.cleanUpDatabases()
	}

	func testCanStartEmptyGroup() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [])
		XCTAssert(!group.id.isEmpty)
		try fixtures.cleanUpDatabases()
	}

	func testCannotStartGroupWithNonRegisteredIdentity() async throws {
		let fixtures = try await fixtures()

		let nonRegistered = try PrivateKey.generate()

		do {
			_ = try await fixtures.alixClient.conversations
				.newGroupWithIdentities(with: [
					PublicIdentity(
						kind: .ethereum, identifier: nonRegistered.walletAddress
					)
				])

			XCTFail("did not throw error")
		} catch {}
		try fixtures.cleanUpDatabases()
	}

	func testGroupStartsWithAllowedState() async throws {
		let fixtures = try await fixtures()
		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID])

		_ = try await boGroup.send(content: "howdy")
		_ = try await boGroup.send(content: "gm")
		try await boGroup.sync()

		let groupStateResult = try boGroup.consentState()
		XCTAssertEqual(groupStateResult, ConsentState.allowed)
		try fixtures.cleanUpDatabases()
	}

	func testCanSendMessagesToGroup() async throws {
		let fixtures = try await fixtures()
		Client.register(codec: GroupUpdatedCodec())
		let alixGroup = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID])
		let membershipChange = GroupUpdated()

		try await fixtures.boClient.conversations.sync()
		let boGroup = try await fixtures.boClient.conversations.listGroups()[
			0]

		_ = try await alixGroup.send(content: "sup gang original")
		let messageId = try await alixGroup.send(content: "sup gang")
		_ = try await alixGroup.send(
			content: membershipChange,
			options: SendOptions(contentType: ContentTypeGroupUpdated))

		try await alixGroup.sync()
		let alixGroupsCount = try await alixGroup.messages().count
		XCTAssertEqual(3, alixGroupsCount)
		let alixMessage = try await alixGroup.messages().first!

		try await boGroup.sync()
		let boGroupsCount = try await boGroup.messages().count
		XCTAssertEqual(3, boGroupsCount)
		let boMessage = try await boGroup.messages().first!

		XCTAssertEqual("sup gang", try alixMessage.content())
		XCTAssertEqual(messageId, alixMessage.id)
		XCTAssertEqual(.published, alixMessage.deliveryStatus)
		XCTAssertEqual("sup gang", try boMessage.content())
		try fixtures.cleanUpDatabases()
	}

	func testCanListGroupMessages() async throws {
		let fixtures = try await fixtures()
		let alixGroup = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID])
		_ = try await alixGroup.send(content: "howdy")
		_ = try await alixGroup.send(content: "gm")

		var alixMessagesCount = try await alixGroup.messages().count
		var alixMessagesPublishedCount = try await alixGroup.messages(
			deliveryStatus: .published
		).count
		XCTAssertEqual(3, alixMessagesCount)
		XCTAssertEqual(3, alixMessagesPublishedCount)

		try await alixGroup.sync()

		alixMessagesCount = try await alixGroup.messages().count
		let alixMessagesUnpublishedCount = try await alixGroup.messages(
			deliveryStatus: .unpublished
		).count
		alixMessagesPublishedCount = try await alixGroup.messages(
			deliveryStatus: .published
		).count
		XCTAssertEqual(3, alixMessagesCount)
		XCTAssertEqual(0, alixMessagesUnpublishedCount)
		XCTAssertEqual(3, alixMessagesPublishedCount)

		try await fixtures.boClient.conversations.sync()
		let boGroup = try await fixtures.boClient.conversations.listGroups()[
			0]
		try await boGroup.sync()

		let boMessagesCount = try await boGroup.messages().count
		let boMessagesUnpublishedCount = try await boGroup.messages(
			deliveryStatus: .unpublished
		).count
		let boMessagesPublishedCount = try await boGroup.messages(
			deliveryStatus: .published
		).count
		XCTAssertEqual(3, boMessagesCount)
		XCTAssertEqual(0, boMessagesUnpublishedCount)
		XCTAssertEqual(3, boMessagesPublishedCount)
		try fixtures.cleanUpDatabases()

	}

	func testCanStreamGroupMessages() async throws {
		let fixtures = try await fixtures()
		Client.register(codec: GroupUpdatedCodec())
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.alixClient.inboxID
		])
		let membershipChange = GroupUpdated()
		let expectation1 = XCTestExpectation(description: "got a message")
		expectation1.expectedFulfillmentCount = 1

		Task(priority: .userInitiated) {
			for try await _ in group.streamMessages() {
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await group.send(
			content: membershipChange,
			options: SendOptions(contentType: ContentTypeGroupUpdated))

		await fulfillment(of: [expectation1], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testCanStreamGroups() async throws {
		let fixtures = try await fixtures()

		let expectation1 = XCTestExpectation(description: "got a group")
		expectation1.expectedFulfillmentCount = 1

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.alixClient.conversations
				.stream(type: .groups)
			{
				expectation1.fulfill()
			}
		}

		_ = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.alixClient.inboxID
		])
		_ = try await fixtures.caroClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)

		await fulfillment(of: [expectation1], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testStreamGroupsAndAllMessages() async throws {
		let fixtures = try await fixtures()

		let expectation1 = XCTestExpectation(description: "got a group")
		let expectation2 = XCTestExpectation(description: "got a message")

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.alixClient.conversations
				.stream()
			{
				expectation1.fulfill()
			}
		}

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.alixClient.conversations
				.streamAllMessages()
			{
				expectation2.fulfill()
			}
		}

		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.alixClient.inboxID
		])
		_ = try await group.send(content: "hello")

		await fulfillment(of: [expectation1, expectation2], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testCanStreamAndUpdateNameWithoutForkingGroup() async throws {
		let fixtures = try await fixtures()

		let expectation = XCTestExpectation(description: "got a message")
		expectation.expectedFulfillmentCount = 5

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.boClient.conversations
				.streamAllMessages()
			{
				expectation.fulfill()
			}
		}

		let alixGroup = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID])
		try await alixGroup.updateName(name: "hello")
		_ = try await alixGroup.send(content: "hello1")

		try await fixtures.boClient.conversations.sync()

		let boGroups = try await fixtures.boClient.conversations.listGroups()
		XCTAssertEqual(boGroups.count, 1, "bo should have 1 group")
		let boGroup = boGroups[0]
		try await boGroup.sync()

		let boMessages1 = try await boGroup.messages()
		XCTAssertEqual(
			boMessages1.count, 3,
			"should have 3 messages on first load received \(boMessages1.count)"
		)

		_ = try await boGroup.send(content: "hello2")
		_ = try await boGroup.send(content: "hello3")
		try await alixGroup.sync()

		let alixMessages = try await alixGroup.messages()
		for message in alixMessages {
			print(
				"message", try message.encodedContent.type,
				try message.encodedContent.type.typeID)
		}
		XCTAssertEqual(
			alixMessages.count, 5,
			"should have 5 messages on first load received \(alixMessages.count)"
		)

		_ = try await alixGroup.send(content: "hello4")
		try await boGroup.sync()

		let boMessages2 = try await boGroup.messages()
		for message in boMessages2 {
			print(
				"message", try message.encodedContent.type,
				try message.encodedContent.type.typeID)
		}
		XCTAssertEqual(
			boMessages2.count, 6,
			"should have 6 messages on second load received \(boMessages2.count)"
		)

		await fulfillment(of: [expectation], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testCanStreamAllGroupMessages() async throws {
		let fixtures = try await fixtures()

		let expectation1 = XCTestExpectation(description: "got a conversation")

		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.alixClient.inboxID
		])
		let dm = try await fixtures.caroClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		try await fixtures.alixClient.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in await fixtures.alixClient.conversations
				.streamAllMessages(type: .groups)
			{
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await dm.send(content: "hi")

		await fulfillment(of: [expectation1], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testCanUpdateGroupMetadata() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.alixClient.conversations.newGroup(
			with: [fixtures.boClient.inboxID], name: "Start Name",
			imageUrl: "starturl.com")

		var groupName = try group.name()
		var groupImageUrlSquare = try group.imageUrl()

		XCTAssertEqual(groupName, "Start Name")
		XCTAssertEqual(groupImageUrlSquare, "starturl.com")

		try await group.updateName(name: "Test Group Name 1")
		try await group.updateImageUrl(imageUrl: "newurl.com")

		groupName = try group.name()
		groupImageUrlSquare = try group.imageUrl()

		XCTAssertEqual(groupName, "Test Group Name 1")
		XCTAssertEqual(groupImageUrlSquare, "newurl.com")

		try await fixtures.boClient.conversations.sync()
		let boGroup = try await fixtures.boClient.conversations.findGroup(
			groupId: group.id)!
		groupName = try boGroup.name()
		XCTAssertEqual(groupName, "Start Name")

		try await boGroup.sync()
		groupName = try boGroup.name()
		groupImageUrlSquare = try boGroup.imageUrl()

		XCTAssertEqual(groupImageUrlSquare, "newurl.com")
		XCTAssertEqual(groupName, "Test Group Name 1")
		try fixtures.cleanUpDatabases()
	}

	func testGroupConsent() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.alixClient.inboxID
		])
		XCTAssertEqual(try group.consentState(), .allowed)

		try await group.updateConsentState(state: .denied)
		let isDenied = try await fixtures.boClient.preferences
			.conversationState(conversationId: group.id)
		XCTAssertEqual(isDenied, .denied)
		XCTAssertEqual(try group.consentState(), .denied)

		try await group.updateConsentState(state: .allowed)
		XCTAssertEqual(try group.consentState(), .allowed)
		try fixtures.cleanUpDatabases()
	}

	func testCanAllowAndDenyInboxId() async throws {
		let fixtures = try await fixtures()
		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID])
		let inboxState = try await fixtures.boClient.preferences
			.inboxIdState(
				inboxId: fixtures.alixClient.inboxID)
		XCTAssertEqual(inboxState, .unknown)

		try await fixtures.boClient.preferences.setConsentState(
			entries: [
				ConsentRecord(
					value: fixtures.alixClient.inboxID, entryType: .inbox_id,
					consentType: .allowed)
			])
		var alixMember = try await boGroup.members.first(where: { member in
			member.inboxId == fixtures.alixClient.inboxID
		})
		XCTAssertEqual(alixMember?.consentState, .allowed)

		let inboxState2 = try await fixtures.boClient.preferences
			.inboxIdState(
				inboxId: fixtures.alixClient.inboxID)
		XCTAssertEqual(inboxState2, .allowed)

		try await fixtures.boClient.preferences.setConsentState(
			entries: [
				ConsentRecord(
					value: fixtures.alixClient.inboxID, entryType: .inbox_id,
					consentType: .denied)
			])
		alixMember = try await boGroup.members.first(where: { member in
			member.inboxId == fixtures.alixClient.inboxID
		})
		XCTAssertEqual(alixMember?.consentState, .denied)

		let inboxState3 = try await fixtures.boClient.preferences
			.inboxIdState(
				inboxId: fixtures.alixClient.inboxID)
		XCTAssertEqual(inboxState3, .denied)
		try fixtures.cleanUpDatabases()
	}

	func testCanFetchGroupById() async throws {
		let fixtures = try await fixtures()

		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID])
		try await fixtures.alixClient.conversations.sync()
		let alixGroup = try await fixtures.alixClient.conversations.findGroup(
			groupId: boGroup.id)

		XCTAssertEqual(alixGroup?.id, boGroup.id)
		try fixtures.cleanUpDatabases()
	}

	func testCanFetchMessageById() async throws {
		let fixtures = try await fixtures()

		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID])

		let boMessageId = try await boGroup.send(content: "Hello")
		try await fixtures.alixClient.conversations.sync()
		let alixGroup = try await fixtures.alixClient.conversations.findGroup(
			groupId: boGroup.id)
		try await alixGroup?.sync()
		_ = try await fixtures.alixClient.conversations.findMessage(
			messageId: boMessageId)

		XCTAssertEqual(alixGroup?.id, boGroup.id)
		try fixtures.cleanUpDatabases()
	}

	func testUnpublishedMessages() async throws {
		let fixtures = try await fixtures()
		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID])

		try await fixtures.alixClient.conversations.sync()
		let alixGroup = try await fixtures.alixClient.conversations.findGroup(
			groupId: boGroup.id)!
		let isGroupAllowed = try await fixtures.alixClient.preferences
			.conversationState(conversationId: boGroup.id)
		XCTAssertEqual(isGroupAllowed, .unknown)
		let preparedMessageId = try await alixGroup.prepareMessage(
			content: "Test text")

		let messageCount = try await alixGroup.messages().count
		XCTAssertEqual(messageCount,2)
		let messageCountPublished = try await alixGroup.messages(
			deliveryStatus: .published
		).count
		let messageCountUnpublished = try await alixGroup.messages(
			deliveryStatus: .unpublished
		).count
		XCTAssertEqual(messageCountPublished, 1)
		XCTAssertEqual(messageCountUnpublished, 1)

		_ = try await alixGroup.publishMessages()
		try await alixGroup.sync()
		let isGroupAllowed2 = try await fixtures.alixClient.preferences
			.conversationState(conversationId: boGroup.id)
		XCTAssertEqual(isGroupAllowed2, .allowed)

		let messageCountPublished2 = try await alixGroup.messages(
			deliveryStatus: .published
		).count
		let messageCountUnpublished2 = try await alixGroup.messages(
			deliveryStatus: .unpublished
		).count
		let messageCount2 = try await alixGroup.messages().count
		XCTAssertEqual(messageCountPublished2, 2)
		XCTAssertEqual(messageCountUnpublished2, 0)
		XCTAssertEqual(messageCount2, 2)

		let messages = try await alixGroup.messages()

		XCTAssertEqual(preparedMessageId, messages.first!.id)
		try fixtures.cleanUpDatabases()
	}

	func testCanSyncManyGroupsInUnderASecond() async throws {
		let fixtures = try await fixtures()
		var groups: [Group] = []

		for _ in 0..<100 {
			let group = try await fixtures.alixClient.conversations.newGroup(
				with: [fixtures.boClient.inboxID])
			groups.append(group)
		}
		try await fixtures.boClient.conversations.sync()
		let boGroup = try await fixtures.boClient.conversations.findGroup(
			groupId: groups[0].id)
		_ = try await groups[0].send(content: "hi")
		let messageCount = try await boGroup!.messages().count
		XCTAssertEqual(messageCount, 1)
		do {
			let start = Date()
			let numGroupsSynced = try await fixtures.boClient.conversations
				.syncAllConversations()
			let end = Date()
			print(end.timeIntervalSince(start))
			XCTAssert(end.timeIntervalSince(start) < 1)
			XCTAssertEqual(numGroupsSynced, 101)
		} catch {
			print("Failed to list groups members: \(error)")
			throw error  // Rethrow the error to fail the test if group creation fails
		}

		let messageCount2 = try await boGroup!.messages().count
		XCTAssertEqual(messageCount2, 2)

		for alixConv in try await fixtures.alixClient.conversations.list() {
			guard case let .group(alixGroup) = alixConv else {
				XCTFail("failed converting conversation to group")
				return
			}
			try await alixGroup.removeMembers(inboxIds: [
				fixtures.boClient.inboxID
			])
		}

		// first syncAllGroups after removal still sync groups in order to process the removal
		var numGroupsSynced = try await fixtures.boClient.conversations
			.syncAllConversations()
		XCTAssertEqual(numGroupsSynced, 101)

		// next syncAllGroups only will sync active groups
		numGroupsSynced = try await fixtures.boClient.conversations
			.syncAllConversations()
		XCTAssertEqual(numGroupsSynced, 1)
		try fixtures.cleanUpDatabases()
	}

	func testCanListManyMembersInParallelInUnderASecond() async throws {
		let fixtures = try await fixtures()
		var groups: [Group] = []

		for _ in 0..<100 {
			let group = try await fixtures.alixClient.conversations.newGroup(
				with: [fixtures.boClient.inboxID])
			groups.append(group)
		}
		do {
			let start = Date()
			let _ = try await listMembersInParallel(groups: groups)
			let end = Date()
			print(end.timeIntervalSince(start))
			XCTAssert(end.timeIntervalSince(start) < 1)
		} catch {
			print("Failed to list groups members: \(error)")
			throw error  // Rethrow the error to fail the test if group creation fails
		}
		try fixtures.cleanUpDatabases()
	}

	func listMembersInParallel(groups: [Group]) async throws {
		await withThrowingTaskGroup(of: [Member].self) { taskGroup in
			for group in groups {
				taskGroup.addTask {
					return try await group.members
				}
			}
		}
	}

	func testGroupDisappearingMessages() async throws {
		let fixtures = try await fixtures()

		let initialSettings = DisappearingMessageSettings(
			disappearStartingAtNs: 1_000_000_000,
			retentionDurationInNs: 1_000_000_000  // 1s duration
		)

		// Create group with disappearing messages enabled
		let boGroup = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.alixClient.inboxID],
			disappearingMessageSettings: initialSettings
		)
		_ = try await boGroup.send(content: "howdy")
		_ = try await fixtures.alixClient.conversations.syncAllConversations()

		let alixGroup = try await fixtures.alixClient.conversations.findGroup(
			groupId: boGroup.id)

		let boGroupMessagesCount = try await boGroup.messages().count
		let alixGroupMessagesCount = try await alixGroup?.messages().count
		let boGroupSettings = boGroup.disappearingMessageSettings

		// Validate messages exist and settings are applied
		XCTAssertEqual(boGroupMessagesCount, 2)  // memberAdd, howdy
		XCTAssertEqual(alixGroupMessagesCount, 2)  // memberAdd, howdy
		XCTAssertNotNil(boGroupSettings)

		try await Task.sleep(nanoseconds: 5_000_000_000)  // Sleep for 5 seconds

		let boGroupMessagesAfterSleep = try await boGroup.messages().count
		let alixGroupMessagesAfterSleep = try await alixGroup?.messages().count

		// Validate messages are deleted
		XCTAssertEqual(boGroupMessagesAfterSleep, 1)  // memberAdd
		XCTAssertEqual(alixGroupMessagesAfterSleep, 1) // memberAdd

		// Set message disappearing settings to nil
		try await boGroup.updateDisappearingMessageSettings(nil)
		try await boGroup.sync()
		try await alixGroup?.sync()

		let boGroupSettingsAfterNil = boGroup.disappearingMessageSettings
		let alixGroupSettingsAfterNil = alixGroup?.disappearingMessageSettings

		XCTAssertNil(boGroupSettingsAfterNil)
		XCTAssertNil(alixGroupSettingsAfterNil)
		XCTAssertFalse(try boGroup.isDisappearingMessagesEnabled())
		XCTAssertFalse(try alixGroup!.isDisappearingMessagesEnabled())

		// Send messages after disabling disappearing settings
		_ = try await boGroup.send(
			content: "message after disabling disappearing")
		_ = try await alixGroup?.send(
			content: "another message after disabling")
		try await boGroup.sync()

		try await Task.sleep(nanoseconds: 5_000_000_000)  // Sleep for 5 seconds

		let boGroupMessagesPersist = try await boGroup.messages().count
		let alixGroupMessagesPersist = try await alixGroup?.messages().count

		// Ensure messages persist
		XCTAssertEqual(boGroupMessagesPersist, 5)  // memberAdd, settings 1, settings 2, boMessage, alixMessage
		XCTAssertEqual(alixGroupMessagesPersist, 5)  // memberAdd, settings 1, settings 2, boMessage, alixMessage

		// Re-enable disappearing messages
		let updatedSettings = await DisappearingMessageSettings(
			disappearStartingAtNs: try boGroup.messages().first!.sentAtNs
				+ 1_000_000_000,  // 1s from now
			retentionDurationInNs: 1_000_000_000  // 2s duration
		)
		try await boGroup.updateDisappearingMessageSettings(updatedSettings)
		try await boGroup.sync()
		try await alixGroup?.sync()
		try await Task.sleep(nanoseconds: 1_000_000_000)  // Sleep for 1 second

		let boGroupUpdatedSettings = boGroup.disappearingMessageSettings
		let alixGroupUpdatedSettings = alixGroup?.disappearingMessageSettings

		XCTAssertEqual(
			boGroupUpdatedSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)
		XCTAssertEqual(
			alixGroupUpdatedSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)

		// Send new messages
		_ = try await boGroup.send(content: "this will disappear soon")
		_ = try await alixGroup?.send(content: "so will this")
		try await boGroup.sync()

		let boGroupMessagesAfterNewSend = try await boGroup.messages().count
		let alixGroupMessagesAfterNewSend = try await alixGroup?.messages()
			.count

		XCTAssertEqual(boGroupMessagesAfterNewSend, 9)
		XCTAssertEqual(alixGroupMessagesAfterNewSend, 9)

		try await Task.sleep(nanoseconds: 6_000_000_000)  // Sleep for 6 seconds to let messages disappear

		let boGroupMessagesFinal = try await boGroup.messages().count
		let alixGroupMessagesFinal = try await alixGroup?.messages().count

		// Validate messages were deleted
		XCTAssertEqual(boGroupMessagesFinal, 7)
		XCTAssertEqual(alixGroupMessagesFinal, 7)

		// Final validation that settings persist
		let boGroupFinalSettings = boGroup.disappearingMessageSettings
		let alixGroupFinalSettings = alixGroup?.disappearingMessageSettings

		XCTAssertEqual(
			boGroupFinalSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)
		XCTAssertEqual(
			alixGroupFinalSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)
		XCTAssert(try boGroup.isDisappearingMessagesEnabled())
		XCTAssert(try alixGroup!.isDisappearingMessagesEnabled())
		try fixtures.cleanUpDatabases()
	}
    
    func testGroupPausedForVersionReturnsNone() async throws {
        let fixtures = try await fixtures()
        
        // Create group with disappearing messages enabled
        let boGroup = try await fixtures.boClient.conversations.newGroup(
            with: [fixtures.alixClient.inboxID]
        )
        
        let pausedForVersionGroup = try boGroup.pausedForVersion()
        XCTAssert(pausedForVersionGroup == nil)
        
        let boDm = try await fixtures.boClient.conversations.newConversation(with: fixtures.alixClient.inboxID)
        let pausedForVersionDm = try await boDm.pausedForVersion()
        XCTAssert(pausedForVersionDm == nil)
		try fixtures.cleanUpDatabases()
    }
    
}
