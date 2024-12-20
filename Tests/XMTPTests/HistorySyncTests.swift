//
//  HistorySyncTests.swift
//  XMTPiOS
//
//  Created by Naomi Plasterer on 12/19/24.
//

import Foundation
import XCTest

@testable import XMTPiOS

@available(iOS 15, *)
class HistorySyncTests: XCTestCase {
	func testSyncConsent() async throws {
		let fixtures = try await fixtures()
		
		let key = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()
		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)
		
		let group = try await alixClient.conversations.newGroup(
			with: [fixtures.bo.walletAddress])
		try await group.updateConsentState(state: .denied)
		XCTAssertEqual(try group.consentState(), .denied)
		
		
		let alixClient2 = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db2"
			)
		)
		
		let state = try await alixClient2.inboxState(refreshFromNetwork: true)
		XCTAssertEqual(state.installations.count, 2)
		
		try await alixClient2.preferences.syncConsent()
		try await alixClient.conversations.syncAllConversations()
		sleep(2)
		try await alixClient2.conversations.syncAllConversations()
		sleep(2)
		
		if let dm2 = try await alixClient2.findConversation(conversationId: group.id) {
			XCTAssertEqual(try dm2.consentState(), .denied)
			
			try await alixClient2.preferences.setConsentState(
				entries: [
					ConsentRecord(
						value: dm2.id,
						entryType: .conversation_id,
						consentType: .allowed
					)
				]
			)
			let convoState = try await alixClient2.preferences
				.conversationState(
					conversationId: dm2.id)
			XCTAssertEqual(convoState, .allowed)
			XCTAssertEqual(try dm2.consentState(), .allowed)
		}
	}
	
	func testSyncMessages() async throws {
		let fixtures = try await fixtures()
		
		let key = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()
		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)
		
		let group = try await alixClient.conversations.newGroup(
			with: [fixtures.bo.walletAddress])
		try await group.send(content: "hi")
		let messageCount = try await group.messages().count
		XCTAssertEqual(messageCount, 2)
		
		let alixClient2 = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db2"
			)
		)
		
		let state = try await alixClient2.inboxState(refreshFromNetwork: true)
		XCTAssertEqual(state.installations.count, 2)
		
		try await alixClient.conversations.syncAllConversations()
		sleep(2)
		try await alixClient2.conversations.syncAllConversations()
		sleep(2)
		
		if let dm2 = try await alixClient2.findConversation(conversationId: group.id) {
			let messageCount = try await group.messages().count
			XCTAssertEqual(messageCount, 2)
		}
	}
	
	
	func testStreamConsent() async throws {
		let fixtures = try await fixtures()
		
		let key = try Crypto.secureRandomBytes(count: 32)
		let alix = try PrivateKey.generate()
		
		let alixClient = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db"
			)
		)
		
		let alixGroup = try await alixClient.conversations.newGroup(with: [fixtures.bo.walletAddress])
		
		let alixClient2 = try await Client.create(
			account: alix,
			options: .init(
				api: .init(env: .local, isSecure: false),
				dbEncryptionKey: key,
				dbDirectory: "xmtp_db2"
			)
		)
		
		try await alixGroup.send(content: "Hello")
		try await alixClient.conversations.syncAllConversations()
		try await alixClient2.conversations.syncAllConversations()
		let alixGroup2 = try alixClient2.findGroup(groupId: alixGroup.id)!
		
		var consentList = [ConsentRecord]()
		let expectation = XCTestExpectation(description: "Stream Consent")
		expectation.expectedFulfillmentCount = 3
		
		Task(priority: .userInitiated) {
			for try await entry in await alixClient.preferences.streamConsent() {
				consentList.append(entry)
				expectation.fulfill()
			}
		}
		sleep(1)
		try await alixGroup2.updateConsentState(state: .denied)
		let dm = try await alixClient2.conversations.newConversation(with: fixtures.caro.walletAddress)
		try await dm.updateConsentState(state: .denied)
		
		sleep(5)
		try await alixClient.conversations.syncAllConversations()
		try await alixClient2.conversations.syncAllConversations()
		
		await fulfillment(of: [expectation], timeout: 3)
		print(consentList)
		XCTAssertEqual(try alixGroup.consentState(), .denied)
	}
}
