//
//  ConversationTests.swift
//
//
//  Created by Pat Nakajima on 12/6/22.
//

import XCTest
@testable import XMTP

class ConversationTests: XCTestCase {
	var alice: PrivateKey!
	var aliceClient: Client!

	var aliceApiClient: FakeApiClient!
	var bobApiClient: FakeApiClient!

	var bob: PrivateKey!
	var bobClient: Client!

	override func setUp() async throws {
		alice = try PrivateKey.generate()
		bob = try PrivateKey.generate()

		aliceApiClient = FakeApiClient()
		aliceClient = try await Client.create(account: alice, apiClient: aliceApiClient)

		bobApiClient = FakeApiClient()
		bobClient = try await Client.create(account: bob, apiClient: bobApiClient)
	}

	func testCanInitiateConversation() async throws {
		let existingConversations = try await aliceClient.conversations.list()
		XCTAssert(existingConversations.isEmpty, "already had conversations somehow")
	}
}
