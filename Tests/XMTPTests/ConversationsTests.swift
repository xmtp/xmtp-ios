import LibXMTP
import XCTest
import XMTPTestHelpers

@testable import XMTPiOS

@available(iOS 16, *)
class ConversationsTests: XCTestCase {
	func testsCanCreateGroup() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caro.address
		])
		let members = try await group.members.map(\.inboxId).sorted()
		XCTAssertEqual(
			[fixtures.caroClient.inboxID, fixtures.boClient.inboxID]
				.sorted(), members)

		await assertThrowsAsyncError(
			try await fixtures.boClient.conversations.newGroup(with: [
				PrivateKey().address
			])
		)
	}

	func testCanCreateDm() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.walletAddress)
		let members = try await dm.members
		XCTAssertEqual(members.count, 2)

		let sameDm = try await fixtures.boClient.findDm(
			address: fixtures.caro.walletAddress)
		XCTAssertEqual(sameDm?.id, dm.id)

		try await fixtures.caroClient.conversations.sync()
		let caroDm = try await fixtures.caroClient.findDm(
			address: fixtures.boClient.address)
		XCTAssertEqual(caroDm?.id, dm.id)

		await assertThrowsAsyncError(
			try await fixtures.boClient.conversations.findOrCreateDm(
				with: PrivateKey().address)
		)
	}

	func testCanFindConversationByTopic() async throws {
		let fixtures = try await fixtures()

		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caro.walletAddress
		])
		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.walletAddress)

		let sameDm = try fixtures.boClient.findConversationByTopic(
			topic: dm.topic)
		let sameGroup = try fixtures.boClient.findConversationByTopic(
			topic: group.topic)

		XCTAssertEqual(group.id, try sameGroup?.id)
		XCTAssertEqual(dm.id, try sameDm?.id)
	}

	func testCanListConversations() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.walletAddress)
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caro.walletAddress
		])

		let convoCount = try await fixtures.boClient.conversations
			.list().count
		let dmCount = try await fixtures.boClient.conversations.listDms().count
		let groupCount = try await fixtures.boClient.conversations.listGroups()
			.count
		XCTAssertEqual(convoCount, 2)
		XCTAssertEqual(dmCount, 1)
		XCTAssertEqual(groupCount, 1)

		try await fixtures.caroClient.conversations.sync()
		let convoCount2 = try await fixtures.caroClient.conversations.list()
			.count
		let groupCount2 = try await fixtures.caroClient.conversations
			.listGroups().count
		XCTAssertEqual(convoCount2, 1)
		XCTAssertEqual(groupCount2, 1)
	}

	func testCanListConversationsFiltered() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.walletAddress)
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caro.walletAddress
		])

		let convoCount = try await fixtures.boClient.conversations
			.list().count
		let convoCountConsent = try await fixtures.boClient.conversations
			.list(consentState: .allowed).count

		XCTAssertEqual(convoCount, 2)
		XCTAssertEqual(convoCountConsent, 2)

		try await group.updateConsentState(state: .denied)

		let convoCountAllowed = try await fixtures.boClient.conversations
			.list(consentState: .allowed).count
		let convoCountDenied = try await fixtures.boClient.conversations
			.list(consentState: .denied).count

		XCTAssertEqual(convoCountAllowed, 1)
		XCTAssertEqual(convoCountDenied, 1)
	}

	func testCanListConversationsOrder() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.walletAddress)
		let group1 = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.caro.walletAddress])
		let group2 = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.caro.walletAddress])

		_ = try await dm.send(content: "Howdy")
		_ = try await group2.send(content: "Howdy")
		_ = try await fixtures.boClient.conversations.syncAllConversations()

		let conversations = try await fixtures.boClient.conversations
			.list()
		let conversationsOrdered = try await fixtures.boClient.conversations
			.list(order: .lastMessage)

		XCTAssertEqual(conversations.count, 3)
		XCTAssertEqual(conversationsOrdered.count, 3)

		XCTAssertEqual(
			try conversations.map { try $0.id }, [dm.id, group1.id, group2.id])
		XCTAssertEqual(
			try conversationsOrdered.map { try $0.id },
			[group2.id, dm.id, group1.id])
	}

	func testsCanSendMessages() async throws {
		let fixtures = try await fixtures()
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caro.address
		])
		try await group.send(content: "howdy")
		let messageId = try await group.send(content: "gm")
		try await group.sync()

		let groupMessages = try await group.messages()
		XCTAssertEqual(groupMessages.first?.body, "gm")
		XCTAssertEqual(groupMessages.first?.id, messageId)
		XCTAssertEqual(groupMessages.first?.deliveryStatus, .published)
		XCTAssertEqual(groupMessages.count, 3)

		try await fixtures.caroClient.conversations.sync()
		let sameGroup = try await fixtures.caroClient.conversations.listGroups()
			.last
		try await sameGroup?.sync()

		let sameGroupMessages = try await sameGroup?.messages()
		XCTAssertEqual(sameGroupMessages?.count, 2)
		XCTAssertEqual(sameGroupMessages?.first?.body, "gm")
	}

	func testsCanSendMessagesToDm() async throws {
		let fixtures = try await fixtures()
		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.address)
		try await dm.send(content: "howdy")
		let messageId = try await dm.send(content: "gm")
		try await dm.sync()

		let dmMessages = try await dm.messages()
		XCTAssertEqual(dmMessages.first?.body, "gm")
		XCTAssertEqual(dmMessages.first?.id, messageId)
		XCTAssertEqual(dmMessages.first?.deliveryStatus, .published)
		XCTAssertEqual(dmMessages.count, 3)

		try await fixtures.caroClient.conversations.sync()
		let sameDm = try await fixtures.caroClient.findDm(
			address: fixtures.boClient.address)
		try await sameDm?.sync()

		let sameDmMessages = try await sameDm?.messages()
		XCTAssertEqual(sameDmMessages?.count, 2)
		XCTAssertEqual(sameDmMessages?.first?.body, "gm")
	}

	func testCanStreamAllMessages() async throws {
		let fixtures = try await fixtures()

		let expectation1 = XCTestExpectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2
		let convo = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.address)
		let group = try await fixtures.caroClient.conversations.newGroup(
			with: [fixtures.bo.address])
		try await fixtures.boClient.conversations.sync()
		Task(priority: .userInitiated) {
			for try await _ in await fixtures.boClient.conversations
				.streamAllMessages()
			{
				expectation1.fulfill()
			}
		}

		_ = try await group.send(content: "hi")
		_ = try await convo.send(content: "hi")

		await fulfillment(of: [expectation1], timeout: 3)
	}

	func testCanStreamGroupsAndConversations() async throws {
		let fixtures = try await fixtures()

		let expectation1 = XCTestExpectation(description: "got a conversation")
		expectation1.expectedFulfillmentCount = 2

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.boClient.conversations
				.stream()
			{
				expectation1.fulfill()
			}
		}

		_ = try await fixtures.caroClient.conversations.newGroup(with: [
			fixtures.bo.address
		])
		_ = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caro.address)

		await fulfillment(of: [expectation1], timeout: 3)
	}
}
