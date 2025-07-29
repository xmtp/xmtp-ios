import LibXMTP
import XCTest
import XMTPTestHelpers

@testable import XMTPiOS

@available(iOS 16, *)
class DmTests: XCTestCase {

	func testCanFindDmByInboxId() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caroClient.inboxID)

		let caroDm = try await fixtures.boClient.conversations.findDmByInboxId(
			inboxId: fixtures.caroClient.inboxID)
		let alixDm = try await fixtures.boClient.conversations.findDmByInboxId(
			inboxId: fixtures.alixClient.inboxID)

		XCTAssertNil(alixDm)
		XCTAssertEqual(caroDm?.id, dm.id)
		try fixtures.cleanUpDatabases()
	}

	func testCanFindDmByAddress() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caroClient.inboxID)

		let caroDm = try await fixtures.boClient.conversations.findDmByIdentity(
			publicIdentity: fixtures.caro.identity)
		let alixDm = try await fixtures.boClient.conversations.findDmByIdentity(
			publicIdentity: fixtures.alix.identity)

		XCTAssertNil(alixDm)
		XCTAssertEqual(caroDm?.id, dm.id)
		try fixtures.cleanUpDatabases()
	}

	func testCanCreateADm() async throws {
		let fixtures = try await fixtures()

		let convo1 = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		try await fixtures.alixClient.conversations.sync()
		let sameConvo1 = try await fixtures.alixClient.conversations
			.findOrCreateDm(with: fixtures.boClient.inboxID)
		XCTAssertEqual(convo1.id, sameConvo1.id)
		try fixtures.cleanUpDatabases()
	}

	func testCanCreateADmWithIdentity() async throws {
		let fixtures = try await fixtures()

		let convo1 = try await fixtures.boClient.conversations
			.findOrCreateDmWithIdentity(
				with: fixtures.alix.identity)
		try await fixtures.alixClient.conversations.sync()
		let sameConvo1 = try await fixtures.alixClient.conversations
			.newConversationWithIdentity(with: fixtures.bo.identity)
		XCTAssertEqual(convo1.id, sameConvo1.id)
		try fixtures.cleanUpDatabases()
	}

	func testCanListDmMembers() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		let members = try await dm.members
		XCTAssertEqual(members.count, 2)

		let peer = try dm.peerInboxId
		XCTAssertEqual(peer, fixtures.alixClient.inboxID)
		try fixtures.cleanUpDatabases()
	}

	func testCannotStartDmWithSelf() async throws {
		let fixtures = try await fixtures()

		await assertThrowsAsyncError(
			try await fixtures.alixClient.conversations.findOrCreateDm(
				with: fixtures.alixClient.inboxID)
		)
		try fixtures.cleanUpDatabases()
	}

	func testCannotStartDmWithAddressWhenExpectingInboxId() async throws {
		let fixtures = try await fixtures()

		do {
			_ = try await fixtures.boClient.conversations.newConversation(
				with: fixtures.alix.walletAddress)
			XCTFail("Did not throw error")
		} catch {
			if case let ClientError.invalidInboxId(message) = error {
				XCTAssertEqual(
					message.lowercased(),
					fixtures.alix.walletAddress.lowercased())
			} else {
				XCTFail("Did not throw correct error")
			}
		}
		try fixtures.cleanUpDatabases()
	}

	func testCannotStartDmWithNonRegisteredIdentity() async throws {
		let fixtures = try await fixtures()
		let nonRegistered = try PrivateKey.generate()

		await assertThrowsAsyncError(
			try await fixtures.alixClient.conversations
				.findOrCreateDmWithIdentity(
					with: nonRegistered.identity)
		)
	}

	func testDmStartsWithAllowedState() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		_ = try await dm.send(content: "howdy")
		_ = try await dm.send(content: "gm")
		try await dm.sync()

		let dmState = try await fixtures.boClient.preferences
			.conversationState(conversationId: dm.id)
		XCTAssertEqual(dmState, .allowed)
		XCTAssertEqual(try dm.consentState(), .allowed)
		try fixtures.cleanUpDatabases()
	}

	func testCanListDmsFiltered() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caroClient.inboxID)
		let dm2 = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		let group = try await fixtures.boClient.conversations.newGroup(with: [
			fixtures.caroClient.inboxID
		])

		let convoCount = try await fixtures.boClient.conversations
			.listDms().count
		let convoCountConsent = try await fixtures.boClient.conversations
			.listDms(consentStates: [.allowed]).count

		XCTAssertEqual(convoCount, 2)
		XCTAssertEqual(convoCountConsent, 2)

		try await dm2.updateConsentState(state: .denied)

		let convoCountAllowed = try await fixtures.boClient.conversations
			.listDms(consentStates: [.allowed]).count
		let convoCountDenied = try await fixtures.boClient.conversations
			.listDms(consentStates: [.denied]).count
		let convoCountCombined = try await fixtures.boClient.conversations
			.listDms(consentStates: [.denied, .allowed]).count

		XCTAssertEqual(convoCountAllowed, 1)
		XCTAssertEqual(convoCountDenied, 1)
		XCTAssertEqual(convoCountCombined, 2)
		try fixtures.cleanUpDatabases()
	}

	func testCanListConversationsOrder() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.caroClient.inboxID)
		let dm2 = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		let group2 = try await fixtures.boClient.conversations.newGroup(
			with: [fixtures.caroClient.inboxID])

		_ = try await dm.send(content: "Howdy")
		_ = try await dm2.send(content: "Howdy")
		_ = try await fixtures.boClient.conversations.syncAllConversations()

		let conversations = try await fixtures.boClient.conversations
			.listDms()
		XCTAssertEqual(conversations.count, 2)
		XCTAssertEqual(
			try conversations.map { try $0.id }, [dm2.id, dm.id])
		try fixtures.cleanUpDatabases()
	}

	func testCanSendMessageToDm() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		_ = try await dm.send(content: "howdy")
		let messageId = try await dm.send(content: "gm")
		try await dm.sync()

		let firstMessage = try await dm.messages().first!
		XCTAssertEqual(try firstMessage.body, "gm")
		XCTAssertEqual(firstMessage.id, messageId)
		XCTAssertEqual(firstMessage.deliveryStatus, .published)
		let messages = try await dm.messages()
		XCTAssertEqual(messages.count, 3)

		try await fixtures.alixClient.conversations.sync()
		let sameDm = try await fixtures.alixClient.conversations.listDms().last!
		try await sameDm.sync()

		let sameMessages = try await sameDm.messages()
		XCTAssertEqual(sameMessages.count, 3)
		XCTAssertEqual(try sameMessages.first!.body, "gm")
		try fixtures.cleanUpDatabases()
	}

	func testCanStreamDmMessages() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		try await fixtures.alixClient.conversations.sync()

		let expectation1 = XCTestExpectation(description: "got a message")
		expectation1.expectedFulfillmentCount = 1

		Task(priority: .userInitiated) {
			for try await _ in dm.streamMessages() {
				expectation1.fulfill()
			}
		}

		_ = try await dm.send(content: "hi")

		await fulfillment(of: [expectation1], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testCanStreamDms() async throws {
		let fixtures = try await fixtures()

		let expectation1 = XCTestExpectation(description: "got a group")
		expectation1.expectedFulfillmentCount = 1

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.alixClient.conversations
				.stream(type: .dms)
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

	func testCanStreamAllDmMessages() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		try await fixtures.alixClient.conversations.sync()

		let expectation1 = XCTestExpectation(description: "got a message")
		expectation1.expectedFulfillmentCount = 2

		Task(priority: .userInitiated) {
			for try await _ in await fixtures.alixClient.conversations
				.streamAllMessages(type: .dms)
			{
				expectation1.fulfill()
			}
		}

		_ = try await dm.send(content: "hi")
		let caroDm = try await fixtures.caroClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		_ = try await caroDm.send(content: "hi")

		await fulfillment(of: [expectation1], timeout: 3)
		try fixtures.cleanUpDatabases()
	}

	func testDmConsent() async throws {
		let fixtures = try await fixtures()

		let dm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)

		let isDm = try await fixtures.boClient.preferences
			.conversationState(conversationId: dm.id)
		XCTAssertEqual(isDm, .allowed)
		XCTAssertEqual(try dm.consentState(), .allowed)

		try await fixtures.boClient.preferences.setConsentState(
			entries: [
				ConsentRecord(
					value: dm.id, entryType: .conversation_id,
					consentType: .denied)
			])
		let isDenied = try await fixtures.boClient.preferences
			.conversationState(conversationId: dm.id)
		XCTAssertEqual(isDenied, .denied)
		XCTAssertEqual(try dm.consentState(), .denied)

		try await dm.updateConsentState(state: .allowed)
		let isAllowed = try await fixtures.boClient.preferences
			.conversationState(conversationId: dm.id)
		XCTAssertEqual(isAllowed, .allowed)
		XCTAssertEqual(try dm.consentState(), .allowed)
		try fixtures.cleanUpDatabases()
	}

	func testDmDisappearingMessages() async throws {
		let fixtures = try await fixtures()

		let initialSettings = DisappearingMessageSettings(
			disappearStartingAtNs: 1_000_000_000,
			retentionDurationInNs: 1_000_000_000  // 1s duration
		)

		// Create group with disappearing messages enabled
		let boDm = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID,
			disappearingMessageSettings: initialSettings
		)
		_ = try await boDm.send(content: "howdy")
		_ = try await fixtures.alixClient.conversations.syncAllConversations()

		let alixDm = try await fixtures.alixClient.conversations
			.findDmByInboxId(inboxId: fixtures.boClient.inboxID)

		let boGroupMessagesCount = try await boDm.messages().count
		let alixGroupMessagesCount = try await alixDm?.messages().count
		let boGroupSettings = boDm.disappearingMessageSettings

		// Validate messages exist and settings are applied
		XCTAssertEqual(boGroupMessagesCount, 2)  // memberAdd howdy
		XCTAssertEqual(alixGroupMessagesCount, 2)  // memberAdd howdy
		XCTAssertNotNil(boGroupSettings)

		try await Task.sleep(nanoseconds: 5_000_000_000)  // Sleep for 5 seconds

		let boGroupMessagesAfterSleep = try await boDm.messages().count
		let alixGroupMessagesAfterSleep = try await alixDm?.messages().count

		// Validate messages are deleted
		XCTAssertEqual(boGroupMessagesAfterSleep, 1)
		XCTAssertEqual(alixGroupMessagesAfterSleep, 1)

		// Set message disappearing settings to nil
		try await boDm.updateDisappearingMessageSettings(nil)
		try await boDm.sync()
		try await alixDm?.sync()

		let boGroupSettingsAfterNil = boDm.disappearingMessageSettings
		let alixGroupSettingsAfterNil = alixDm?.disappearingMessageSettings

		XCTAssertNil(boGroupSettingsAfterNil)
		XCTAssertNil(alixGroupSettingsAfterNil)
		XCTAssertFalse(try boDm.isDisappearingMessagesEnabled())
		XCTAssertFalse(try alixDm!.isDisappearingMessagesEnabled())

		// Send messages after disabling disappearing settings
		_ = try await boDm.send(
			content: "message after disabling disappearing")
		_ = try await alixDm?.send(
			content: "another message after disabling")
		try await boDm.sync()

		try await Task.sleep(nanoseconds: 5_000_000_000)  // Sleep for 5 seconds

		let boGroupMessagesPersist = try await boDm.messages().count
		let alixGroupMessagesPersist = try await alixDm?.messages().count

		// Ensure messages persist
		XCTAssertEqual(boGroupMessagesPersist, 3)  // memberAdd settings 1, settings 2, boMessage, alixMessage
		XCTAssertEqual(alixGroupMessagesPersist, 3)  // memberAdd settings 1, settings 2, boMessage, alixMessage

		// Re-enable disappearing messages
		let updatedSettings = await DisappearingMessageSettings(
			disappearStartingAtNs: try boDm.messages().first!.sentAtNs
				+ 1_000_000_000,  // 1s from now
			retentionDurationInNs: 1_000_000_000  // 2s duration
		)
		try await boDm.updateDisappearingMessageSettings(updatedSettings)
		try await boDm.sync()
		try await alixDm?.sync()
		try await Task.sleep(nanoseconds: 1_000_000_000)  // Sleep for 1 second

		let boGroupUpdatedSettings = boDm.disappearingMessageSettings
		let alixGroupUpdatedSettings = alixDm?.disappearingMessageSettings

		XCTAssertEqual(
			boGroupUpdatedSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)
		XCTAssertEqual(
			alixGroupUpdatedSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)

		// Send new messages
		_ = try await boDm.send(content: "this will disappear soon")
		_ = try await alixDm?.send(content: "so will this")
		try await boDm.sync()

		let boGroupMessagesAfterNewSend = try await boDm.messages().count
		let alixGroupMessagesAfterNewSend = try await alixDm?.messages()
			.count

		XCTAssertEqual(boGroupMessagesAfterNewSend, 5)
		XCTAssertEqual(alixGroupMessagesAfterNewSend, 5)

		try await Task.sleep(nanoseconds: 6_000_000_000)  // Sleep for 6 seconds to let messages disappear

		let boGroupMessagesFinal = try await boDm.messages().count
		let alixGroupMessagesFinal = try await alixDm?.messages().count

		// Validate messages were deleted
		XCTAssertEqual(boGroupMessagesFinal, 3)
		XCTAssertEqual(alixGroupMessagesFinal, 3)

		let boGroupFinalSettings = boDm.disappearingMessageSettings
		let alixGroupFinalSettings = alixDm?.disappearingMessageSettings

		XCTAssertEqual(
			boGroupFinalSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)
		XCTAssertEqual(
			alixGroupFinalSettings!.retentionDurationInNs,
			updatedSettings.retentionDurationInNs)
		XCTAssert(try boDm.isDisappearingMessagesEnabled())
		XCTAssert(try alixDm!.isDisappearingMessagesEnabled())
		try fixtures.cleanUpDatabases()
	}

	func testCanSuccessfullyThreadDms() async throws {
		let fixtures = try await fixtures()

		let convoBo = try await fixtures.boClient.conversations.findOrCreateDm(
			with: fixtures.alixClient.inboxID)
		let convoAlix = try await fixtures.alixClient.conversations
			.findOrCreateDm(with: fixtures.boClient.inboxID)

		try await convoBo.send(content: "Bo hey")
		try await Task.sleep(nanoseconds: 5_000_000_000)  // 5 seconds delay
		try await convoAlix.send(content: "Alix hey")

		let boMessages = try await convoBo.messages().map { try $0.body }
			.joined(separator: ",")
		let alixMessages = try await convoAlix.messages().map { try $0.body }
			.joined(separator: ",")

		print("LOPI Bo original: \(boMessages)")
		print("LOPI Alix original: \(alixMessages)")

		let convoBoMessageCount = try await convoBo.messages().count
		let convoAlixMessageCount = try await convoAlix.messages().count

		XCTAssertEqual(convoBoMessageCount, 2)  // memberAdd and Bo hey
		XCTAssertEqual(convoAlixMessageCount, 2)  // memberAdd and Alix hey

		try await fixtures.boClient.conversations.syncAllConversations()
		try await fixtures.alixClient.conversations.syncAllConversations()

		let convoBoMessageCountAfterSync = try await convoBo.messages().count
		let convoAlixMessageCountAfterSync = try await convoAlix.messages()
			.count

		XCTAssertEqual(convoBoMessageCountAfterSync, 3)  // memberAdd, Bo hey, Alix hey
		XCTAssertEqual(convoAlixMessageCountAfterSync, 3)  // memberAdd, Bo hey, Alix hey

		let sameConvoBo = try await fixtures.alixClient.conversations
			.findOrCreateDm(with: fixtures.boClient.inboxID)
		let sameConvoAlix = try await fixtures.boClient.conversations
			.findOrCreateDm(with: fixtures.alixClient.inboxID)

		let topicBoSame = try await fixtures.boClient.conversations
			.findConversationByTopic(topic: convoBo.topic)
		let topicAlixSame = try await fixtures.alixClient.conversations
			.findConversationByTopic(topic: convoAlix.topic)

		let alixConvoID = convoAlix.id
		let topicBoSameID = topicBoSame?.id
		let topicAlixSameID = topicAlixSame?.id
		let firstAlixDmID = try await fixtures.alixClient.conversations
			.listDms().first?.id
		let firstBoDmID = try await fixtures.boClient.conversations.listDms()
			.first?.id

		XCTAssertEqual(alixConvoID, sameConvoBo.id)
		XCTAssertEqual(alixConvoID, sameConvoAlix.id)
		XCTAssertEqual(alixConvoID, topicBoSameID)
		XCTAssertEqual(alixConvoID, topicAlixSameID)
		XCTAssertEqual(firstAlixDmID, alixConvoID)
		XCTAssertEqual(firstBoDmID, alixConvoID)

		try await sameConvoBo.send(content: "Bo hey2")
		try await sameConvoAlix.send(content: "Alix hey2")
		try await sameConvoAlix.sync()
		try await sameConvoBo.sync()

		let sameConvoBoMessageCount = try await sameConvoBo.messages().count
		let sameConvoAlixMessageCount = try await sameConvoAlix.messages().count

		XCTAssertEqual(sameConvoBoMessageCount, 5)  // memberAdd, Bo hey, Alix hey, Bo hey2, Alix hey2
		XCTAssertEqual(sameConvoAlixMessageCount, 5)  // memberAdd, Bo hey, Alix hey, Bo hey2, Alix hey2
		try fixtures.cleanUpDatabases()
	}

	func testMassiveSyncAndConsentRace() async throws {
		let key = try Crypto.secureRandomBytes(count: 32)
		let wallet = try PrivateKey.generate()

		// Primary client
		let primary = try await Client.create(
			account: wallet,
			options: ClientOptions(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_primary"
			)
		)

		// Create 100 peer clients for DMs
		let dm: Dm = try await primary.conversations.findOrCreateDm(
			with:
				"675ecbeed390b4e6d8dd07a31bbd56f048d3024dfdb841d8f74eec6835be1c3a"
		)
		for id in [
			"6adfb4ceaf0e73f4b762ccf20c22b63a8611691786bbced46db5554e00389177",
			"752683460ed9b8d6dc795e15d835ba967570add66354268b2890ad28f869d99a",
			"a9a10b36e0a84be033a32001af731e0dbdd4ce39aed3755fcf0d56dc7b300126",
			"ea0a6d4933d6f268592f5e90586820f8d7c255342652a511088d0023545bf7dc",
			"cbe801c4e27108349a5f0afa0a5600d1627b75c5fa0b002cbbed4f7844d991cc",
			"aaeef287b7d313281b01cf6e530cb841c743b6b0289f1bd28bfb71918a2f5890",
			"e06ad4945a9c6d7c1b88d4d82cf745378e0c53c2d7f67693accb54f2a4671e56",
			"8e8ba425e0ced9f72832fb7d544127db92af4ffdf1f936214d792512d3fba745",
			"56efac3a6bfe9c33c34c29e128151f24ad794f3d4eb7d7963f1fc038083917e5",
			"70c2cd5305c29eb26e5ff652e82dc089ba3df5c0fc7efde64d6f311522a9ca7e",
			"ad71ea915fb111f04b592ed445eb7b49da3212486eac20e1e28e7deb06894943",
			"50b212b5c5b447710b92bb17e230cd0b17b679434cdb964a176fb5ac463b802b",
			"0f77abb44f9c32cbb88bdb3a8f719cabf1247ee9aa305e876f301cba4a3445d3",
			"4d9c145fca5f2cea058d7cc4eb6d2c9c325f7b091a0d6b4c560d6040a958607f",
			"cb172b54b47482be52dc11ed531ea2c0447d01f8850c74c1254f4a65a4ae88e3",
			"0116a82e1072b465613cb41e445def302b94d81cc780acc9cf644ad9c79af7ca",
			"ca944eec15d06b7d23c22c659f12a7910e72c0d9806dbcaac0d37d8e410532d6",
			"a79e2b9a3c1bd0dd645125b754b572d1ed5fc75f2474827523722d2313c9e1f9",
			"7cb19b47d7cda3f468070d1cf7358221a92cdbf0e7d334db317b3678d0633236",
			"f6a74fbc00a220894075ebf133737b2714e98fdc28d56ca3a441ceeca4d27c23",
			"437a83742f35ff28320dc6f02a1beba614cf742c5a6150fe86864e9c4bb7927f",
			"c458bfd7273e3d15246a0e652e4756cccd0a9741d3c17cfd86f7346b2b1d58b6",
			"184a26b09cd21adf2bea6931bafa3001052cd6ed0dc7f6a8fb8ffd780aff17eb",
			"a00ca689f55581a6fd426658b61df927940502c5626108d425fa7de56e7f3134",
			"07bb57386f73f528b36df3c4d256c1c9c2af21fe2d1e32d135a68ad6a54a322a",
			"f5586808781b2e7b731456850a3ce906e821c71f178218dcaa9533cfaf5fe21e",
			"8e3c5ddccda3c6f5621cd577f3f0c23b33d9fc7b09731872fcdd602954db61f3",
			"be06dcaea9e23c3be79f5aa83d3c799d70eb151b322d21920fc9a84033548bc9",
			"9644a2bdd5ae22f151f0e34a6d728eee894430c007fdcd514b1fe3596d468c17",
			"ce34d8ea03ef5d52c40a5b7b4af776e622517f324c38a87042e5fc7ed666f751",
			"5b967c5964e27c7c84a375b32439245f3fcf0663f2f53c2a924be1840160e3f5",
			"985ce539980618e047c9f2f736936cb8acdf5ba12c95bd1669d6e5863b2cfd88",
			"dff3ac8ef5366f810c286ca99338688dca2034e38510a2b0ad655222b2d1efbd",
			"678cc87ede9c5cef01a04035cb846257e2b2c401f044692754ce8e00661894da",
			"1eecb20db25b6ce8657b6fb3f07c0a4350aca9329782f1df76be8aa0c6ed47e7",
			"cb9572a127ac1e937b9f0745089222b84733c722f1fb40c29b4999403e5f052b",
			"5b6801f9c950f6dca6da0bb9affacd6c371fef0e2fe46c34c6f17e0c7baa4654",
			"e2239674fa807374a28a73b014ba191b492ca1e9fa7632f2b67a8a9d4705c9b4",
			"a450b8a63309fa06e9a07f1931c35514629c1cc572f6ace15af381da5517d520",
			"596ae4c956c71fbc7ce36c35d9a96152ee95262078d89c1562f1b9269a9f6631",
			"ed3de22ae086a63af70c71aba8ce915a6943ed49772959107235348acba89c9d",
			"3ad12c425b50b32770b88a3a8ca597badc1d05188d685c26bd70827da340b025",
			"78b944d80827fbae9f80935e81bf5f7b502244152b07b7a5a5b27de2a627238b",
			"1a6def2c504fea84727116ecf70a5d411965b1f0e9f7f6f909dfb1b83adca1e5",
			"ac8ec77fa63b79da0d2fcd92ed99b62456570a9bef55efa8c30e59552d06cc74",
			"f906d6369f917d370661898b817e4998e494cefa2a993389d1227a9409f0c88d",
			"54a0078958ed2a622c2341ee97f68dca34e26227c95432b685659638f8ac316c",
			"21010be97dc3986e8681552f56e0f8b990bccb6f33fbc498e42090a53fc00fec",
			"4072409602bd8821708acf0a9ae79e312d379384d06ebc420e86b30f3d990413",
			"c6e32a21439987e41c02c7fa55701693d00e60a357efd40361235f611228f605",
			"03ea989b2909d560a8e540577fccd7b123d45c308d38ee2d910ccde0f9a5ab4f",
			"b3c939009e8812494b83d660d558a8158c05094d5a2ac5c1e7198a283997ac8c",
			"3d8e961207a5c9515ebddb6506a0b917315cc1b2e44c7e83863d3afed1f31988",
			"2dea5970a3f4e43c3c146a1340e89e3520d7379fc42ed5d4d04f8f2044aca623",
			"10007fc563a804613bd87fc0efd83aa83a3d029fba942bb8718a01c6c4ede84e",
			"989c2bdfd4a35a3c3d97d9a2dc4a775a5dfbf7c3971ec550b32bbcf1581ee36d",
			"129e18ad94591957c13b6f7cceafdf583fd8a7d152883d12364aa6e9db06b8b3",
			"32ab7474f3f25767bd2b35a7e38794ef444c8359856beed5d6d7765b22adbd47",
			"944377e7ea6277378bf6113da43b2bf74ddc5331d4bc3b46eb9b26255375bb8d",
			"029ab958bdfcf25c1e3d99caa98e90e9ec408c7d21e9648ebc96c09a21d74901",
			"03698ba9a3091532c81b72ef2d27eff1f1f8979567f4e5b7e8fa9e118577b190",
			"182da44a74736d19817d2af7da0d51f755533bed20569aff97a664ea919319d4",
			"b26fd9d9cfe4d4c73dcb71fb5d6da51721f9e8bd2f862697c149f3cb185c8e19",
			"2cc9985c4e4e2ba16c6e6e94609e4e30d765e3475d15aa7e3cda191c2f802ca0",
			"0d674191954f2f1a85d073fb75fc08cb1165156a8deb73a1aa44266ca0a1802e",
			"2fd03814086ed86ced55ea4612ac4ad7a1c2e3f414806029e12026181baaa9da",
			"386310ac3b6c71543ba11d005b5a5dc6c9fbbb14a83ec37baadabdd845cc536d",
			"40ad69b13d709a56f708c53eaf73db890823ec8cf9539d180b50b28c5be3e883",
			"9b73d569eaae1d45ab59b434543757bc4d556d412af4a67155718f9b729f4b21",
			"10d17b24c86acbe561cc34139409a695a62eadc58d26afdfe30c6098b1a25ad9",
			"f979ffbb399defb416964aada49aabb3fcfb255c6961be3caf6178d3c364323a",
			"3d9a91d70cbd7ab0231693b74c30d463a65e9a4fdae0ee9c84861a353a440e78",
			"956e4d9b95882fbc6da8798ec3ddf8d9fbce7a5f2e2904d629728f6798992a4a",
			"a942e14499ee13bb01ce0b77f019c8c2761a960fa847a9fdc55e35e11d294bbf",
			"e23aa61380c376a53701299b841bff1289e21ecdae98d3bd8045dcc7ac48d7f4",
			"2daa2a12157d25377da23b1ccd691cc0c7aa734b9f421bada6b9cd69b2bee15c",
			"9f2493fb4acf06e0518832c64f3fe3867aa0abe1212b648e24ee641a2745dcef",
			"7a669cfa14be613e61d33a923ef05bc515f79221cacbd6f9335278cd235c2d92",
			"2b3727c88a09015d9f93da1ae820c5b1cd28980f457e7db6f6e5a287861ca483",
			"12e966095dd086976673190b540d9b49c2fbae46829e5729910201feae1d1354",
			"2298996cdaa4514cab9f54a489b2f053b898b12b58c1bf6e3fc0294f68a32b8d",
			"28df9bb0497f82225027db8c3ffd95e9b0f96c4832be2edcd9b086feeb847dfa",
			"e74c93111faf9c3ef381ee03db35feb622457740ddfc93810d79a5c6ab5e4be3",
			"b2aa9e937e447301cd0c254c98f263513b2f060532620eed3d4e520d0dea6f8d",
			"d52ba9ef8e352faa101ad996a24b321a933ec470f2a120b038bdb38b0c4035c9",
		] {
			//			let peer = try await Client.create(
			//				account: try PrivateKey.generate(),
			//				options: ClientOptions(
			//					api: .init(env: .local, isSecure: false),
			//					dbEncryptionKey: try Crypto.secureRandomBytes(count: 32),
			//					dbDirectory: "xmtp_peer_\(i)"
			//				)
			//			)
			//			print("LOPI \(peer.inboxID)")
			_ = try await primary.conversations.findOrCreateDm(with: id)
			//			try peer.deleteLocalDatabase()
		}

		// Create 100 group conversations (each with 2 fresh members)
		for _ in 0..<100 {
			_ = try await primary.conversations.newGroup(with: ["675ecbeed390b4e6d8dd07a31bbd56f048d3024dfdb841d8f74eec6835be1c3a"]
			)
		}

		print("Starting sync + consent race")


		let start = Date()

		_ = try await primary.conversations.syncAllConversations()

		let duration = Date().timeIntervalSince(start)
		print(
			"100 groups, 100 DMs created; syncAll + consent change finished in \(duration) seconds"
		)
		assert(duration < 10)
	}

}
