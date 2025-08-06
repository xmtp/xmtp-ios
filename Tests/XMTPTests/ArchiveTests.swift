//
//  ArchiveTests.swift
//  XMTPiOS
//
//  Created by Naomi Plasterer on 8/5/25.
//

import Foundation
import XCTest

@testable import XMTPiOS

@available(iOS 15, *)
class ArchiveTests: XCTestCase {
	func testClientArchives() async throws {
		let fixtures = try await fixtures()
		let key = try Crypto.secureRandomBytes(count: 32)
		let encryptionKey = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()

		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_test1"
			)
		)

		let allPath = "xmtp_test1/testAll.zstd"
		let consentPath = "xmtp_test1/testConsent.zstd"

		let group = try await alixClient.conversations.newGroup(with: [
			fixtures.boClient.inboxID
		])
		try await group.send(content: "hi")

		try await alixClient.conversations.syncAllConversations()
		try await fixtures.boClient.conversations.syncAllConversations()

		let boGroup = try await fixtures.boClient.conversations.findGroup(
			groupId: group.id)!
		try await alixClient.createArchive(
			path: allPath, encryptionKey: encryptionKey)
		try await alixClient.createArchive(
			path: consentPath,
			encryptionKey: encryptionKey,
			opts: .init(archiveElements: [.consent])
		)

		let metadataAll = try await alixClient.archiveMetadata(
			path: allPath, encryptionKey: encryptionKey)
		let metadataConsent = try await alixClient.archiveMetadata(
			path: consentPath, encryptionKey: encryptionKey)

		let allElementsCount = metadataAll.elements.count
		let consentElements = metadataConsent.elements

		XCTAssertEqual(allElementsCount, 2)
		XCTAssertEqual(consentElements, [.consent])

		let alixClient2 = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_test2"
			)
		)

		try await alixClient2.importArchive(
			path: allPath, encryptionKey: encryptionKey)
		try await alixClient.conversations.syncAllConversations()
		sleep(2)
		try await alixClient2.conversations.syncAllConversations()
		sleep(2)
		try await alixClient.preferences.sync()
		sleep(2)
		try await alixClient2.preferences.sync()
		sleep(2)
		try await boGroup.send(content: "hey")
		try await fixtures.boClient.conversations.syncAllConversations()
		sleep(2)
		try await alixClient2.conversations.syncAllConversations()

		let convos = try await alixClient2.conversations.list()
		XCTAssertEqual(convos.count, 1)

		let convo = convos.first!
		try await convo.sync()
		let messagesCount = try await convo.messages().count
		let state = try convo.consentState()

		XCTAssertEqual(messagesCount, 3)
		XCTAssertEqual(state, .allowed)
	}

	func testInActiveDmsStitchIfDuplicated() async throws {
		let fixtures = try await fixtures()
		let key = try Crypto.secureRandomBytes(count: 32)
		let encryptionKey = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()

		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_test1"
			)
		)

		let allPath = "xmtp_test1/testAll.zstd"

		let dm = try await alixClient.conversations.findOrCreateDm(
			with: fixtures.boClient.inboxID)
		try await dm.send(content: "hi")
		try await alixClient.conversations.syncAllConversations()
		try await fixtures.boClient.conversations.syncAllConversations()

		let boDm = try fixtures.boClient.conversations.findDmByInboxId(
			inboxId: alixClient.inboxID)!

		try await alixClient.createArchive(
			path: allPath, encryptionKey: encryptionKey)

		let alixClient2 = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_test2"
			)
		)

		try await alixClient2.importArchive(
			path: allPath, encryptionKey: encryptionKey)
		try await alixClient2.conversations.syncAllConversations()

		let convos = try await alixClient2.conversations.list()
		XCTAssertEqual(convos.count, 1)

		let isInactive = try convos.first!.isActive()
		XCTAssertFalse(isInactive)

		let dm2 = try await alixClient.conversations.findOrCreateDm(
			with: fixtures.boClient.inboxID)
		let isActive = try dm2.isActive()
		XCTAssertTrue(isActive)

		try await boDm.send(content: "hey")
		try await dm2.send(content: "hey")
		try await fixtures.boClient.conversations.syncAllConversations()
		sleep(2)
		try await alixClient2.conversations.syncAllConversations()

		let convos2 = try await alixClient2.conversations.list()
		XCTAssertEqual(convos2.count, 1)

		let dm2MessagesCount = try await dm2.messages().count
		let boDmMessagesCount = try await boDm.messages().count
		XCTAssertEqual(dm2MessagesCount, 4)
		XCTAssertEqual(boDmMessagesCount, 4)
	}

	func testImportArchiveWorksEvenOnFullDatabase() async throws {
		let fixtures = try await fixtures()
		let encryptionKey = try Crypto.secureRandomBytes(count: 32)
		let allPath = "xmtp_test1/testAll.zstd"

		let group = try await fixtures.alixClient.conversations.newGroup(with: [
			fixtures.boClient.inboxID
		])
		let dm = try await fixtures.alixClient.conversations.findOrCreateDm(
			with: fixtures.boClient.inboxID)

		try await group.send(content: "First")
		try await dm.send(content: "hi")

		try await fixtures.alixClient.conversations.syncAllConversations()
		try await fixtures.boClient.conversations.syncAllConversations()

		let boGroup = try await fixtures.boClient.conversations.findGroup(
			groupId: group.id)!

		let groupMessagesCount1 = try await group.messages().count
		let boGroupMessagesCount1 = try await boGroup.messages().count
		let alixListCount1 = try await fixtures.alixClient.conversations.list()
			.count
		let boListCount1 = try await fixtures.boClient.conversations.list()
			.count

		XCTAssertEqual(groupMessagesCount1, 2)
		XCTAssertEqual(boGroupMessagesCount1, 2)
		XCTAssertEqual(alixListCount1, 2)
		XCTAssertEqual(boListCount1, 2)

		try await fixtures.alixClient.createArchive(
			path: allPath, encryptionKey: encryptionKey)
		try await group.send(content: "Second")
		try await fixtures.alixClient.importArchive(
			path: allPath, encryptionKey: encryptionKey)
		try await group.send(content: "Third")
		try await dm.send(content: "hi")

		try await fixtures.alixClient.conversations.syncAllConversations()
		try await fixtures.boClient.conversations.syncAllConversations()

		let groupMessagesCount2 = try await group.messages().count
		let boGroupMessagesCount2 = try await boGroup.messages().count
		let alixListCount2 = try await fixtures.alixClient.conversations.list()
			.count
		let boListCount2 = try await fixtures.boClient.conversations.list()
			.count

		XCTAssertEqual(groupMessagesCount2, 4)
		XCTAssertEqual(boGroupMessagesCount2, 4)
		XCTAssertEqual(alixListCount2, 2)
		XCTAssertEqual(boListCount2, 2)
	}
}
