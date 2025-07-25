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

    // The following typescript code is run using node-sdk against local to prime this test address with 1200 DMs:
    //    for (let i = 0; i < 1200; i++) {
    //        const key = generateEncryptionKeyHex();
    //        const signer = createSigner(key);
    //        const encryptionKey = getEncryptionKeyFromHex(ENCRYPTION_KEY);
    //        const client = await Client.create(signer, {
    //          dbEncryptionKey: encryptionKey,
    //          env: XMTP_ENV as XmtpEnv,
    //          loggingLevel: LogLevel.error,
    //        });
    //        const conversation = await client.conversations.newDmWithIdentifier({
    //          identifier: "0xf4bdf6e634a9b6679a5f8218b1c44a94bc80429f",
    //          identifierKind: IdentifierKind.Ethereum,
    //        });
    //        await conversation.send("Hello, world!");
    //        console.log("\"" + client.accountIdentifier?.identifier + "\",");
    //      }
    func testFunctionsWhileSyncing1200Dms() async throws {
        // ────────── 1.  SETUP ──────────
        let key = Data([
            0x12, 0x34, 0x56, 0x78, 0x9a, 0xbc, 0xde, 0xf0,
            0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88,
            0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff, 0x00, 0x11,
            0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99
        ])
        let privateKeyData = Data(
            hex: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde7"
        )
        let wallet = try PrivateKey(privateKeyData)
        print("CAMERON my address: \(wallet.walletAddress)")

        let primary = try await Client.create(
            account: wallet,
            options: ClientOptions(
                api: .init(env: .local, isSecure: false),
                dbEncryptionKey: key,
                dbDirectory: "xmtp_primary2"
            )
        )

        let identity = PublicIdentity(kind: .ethereum,
                                      identifier: "0x115f1cce7612ca4ddb98ec3de92782be9773869a")
        let canMessage = try await primary.canMessage(identity: identity)
        XCTAssertTrue(canMessage,
                      "should be able to message identity: \(identity.identifier)")

        // ────────── 2.  LAUNCH BACKGROUND SYNC ──────────
        let syncTask = Task<(UInt32, Double), Error> {
            let start = CFAbsoluteTimeGetCurrent()
            let count = try await primary.conversations.syncAllConversations()
            return (count, CFAbsoluteTimeGetCurrent() - start)
        }

        // ────────── 3.  HAMMER READS UNTIL CANCELLED ──────────
        let hammerTask = Task<([String], [Double], [Double], [Double], [Double]), Error> {
            var timings: [String] = []
            var listTimes: [Double] = []
            var messagesTimes: [Double] = []
            var findTimes: [Double] = []
            var updateTimes: [Double] = []
            var i = 0

            do {
                while !Task.isCancelled {
                    i += 1

                    // READ: conversations.list()
                    let listStart = CFAbsoluteTimeGetCurrent()
                    let conversations = try await primary.conversations.list()
                    let listTime = CFAbsoluteTimeGetCurrent() - listStart
                    if conversations.isEmpty {
                        continue
                    }
                    listTimes.append(listTime)
                    timings.append("list() #\(i) ▸ \(String(format: "%.3f", listTime)) s (\(conversations.count) convos)")

                    // READ: conversation.messages()
                    let convo = conversations.randomElement()
                    if convo != nil {
                        let msgStart = CFAbsoluteTimeGetCurrent()
                        let msgs = try await convo?.messages()
                        let msgTime = CFAbsoluteTimeGetCurrent() - msgStart
                        messagesTimes.append(msgTime)
                        timings.append("messages() #\(i) ▸ \(String(format: "%.3f", msgTime)) s (\(msgs?.count ?? 0) msgs)")
                    }
                    
                    // READ: conversations.findConversation()
                    let findStart = CFAbsoluteTimeGetCurrent()
                    let conversation = try await primary.conversations.findConversation(conversationId: convo!.id)
                    let findTime = CFAbsoluteTimeGetCurrent() - findStart
                    findTimes.append(findTime)
                    timings.append("findConversation() #\(i) ▸ \(String(format: "%.3f", findTime)) s (\(conversation?.id ?? "<nil>"))")

                    // update consent
                    let updateStart = CFAbsoluteTimeGetCurrent()
                    let updatedConsent = try await conversation?.updateConsentState(state: .allowed)
                    let updateTime = CFAbsoluteTimeGetCurrent() - updateStart
                    updateTimes.append(updateTime)
                    timings.append("updateConsent() #\(i) ▸ \(String(format: "%.3f", updateTime)) s")

                    // ── yield to give syncTask CPU time ──
                    if Task.isCancelled { break }
                    try await Task.sleep(nanoseconds: 200_000_000)
                }
            } catch is CancellationError {
                // ignore – we just want to return what we collected so far
            }

            return (timings, listTimes, messagesTimes, findTimes, updateTimes)
        }


        // ────────── 4.  WAIT FOR SYNC TO FINISH ──────────
        let (syncedCount, syncElapsed) = try await syncTask.value

        // ────────── 5.  STOP THE HAMMER & COLLECT RESULTS ──────────
        hammerTask.cancel()
        let (timingResults, listTimes, messagesTimes, findTimes, updateTimes) = try await hammerTask.value

        // ────────── 6.  REPORT ──────────
        print("\n=== CAMERON TIMING RESULTS ===")
        timingResults.forEach { print($0) }
        print("syncAllConversations() ▸ \(String(format: "%.3f", syncElapsed)) s " +
              "for \(syncedCount) convos")

        print("\n=== TIMING STATISTICS ===")
        if !listTimes.isEmpty {
            let avgList = listTimes.reduce(0, +) / Double(listTimes.count)
            let maxList = listTimes.max() ?? 0
            print("list() ▸ avg: \(String(format: "%.3f", avgList))s, max: \(String(format: "%.3f", maxList))s (\(listTimes.count) calls)")
        }

        if !messagesTimes.isEmpty {
            let avgMessages = messagesTimes.reduce(0, +) / Double(messagesTimes.count)
            let maxMessages = messagesTimes.max() ?? 0
            print("messages() ▸ avg: \(String(format: "%.3f", avgMessages))s, max: \(String(format: "%.3f", maxMessages))s (\(messagesTimes.count) calls)")
        }

        if !findTimes.isEmpty {
            let avgFind = findTimes.reduce(0, +) / Double(findTimes.count)
            let maxFind = findTimes.max() ?? 0
            print("findConversation() ▸ avg: \(String(format: "%.3f", avgFind))s, max: \(String(format: "%.3f", maxFind))s (\(findTimes.count) calls)")
        }

        if !updateTimes.isEmpty {
            let avgUpdate = updateTimes.reduce(0, +) / Double(updateTimes.count)
            let maxUpdate = updateTimes.max() ?? 0
            print("updateConsent() ▸ avg: \(String(format: "%.3f", avgUpdate))s, max: \(String(format: "%.3f", maxUpdate))s (\(updateTimes.count) calls)")
        }
        print("=== END ===")
        print("CAMERON my address: \(wallet.walletAddress)")
    }


}
