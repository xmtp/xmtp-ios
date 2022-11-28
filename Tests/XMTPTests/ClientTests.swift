//
//  ClientTests.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation

import XCTest
@testable import XMTP

class ClientTests: XCTestCase {
	func testTakesAWallet() async throws {
		let fakeWallet = try PrivateKey.generate()
		_ = try await Client.create(wallet: fakeWallet)
	}

	func testHasAPIClient() async throws {
		let fakeWallet = try PrivateKey.generate()

		var options = ClientOptions()
		options.api.env = .local
		let client = try await Client.create(wallet: fakeWallet, options: options)

		XCTAssert(client.apiClient.environment == .local)
	}

	func testHasPrivateKeyBundleV1() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(wallet: fakeWallet)

		XCTAssertEqual(1, client.privateKeyBundleV1.preKeys.count)

		let preKey = client.privateKeyBundleV1.preKeys[0]

		XCTAssert(preKey.publicKey.hasSignature, "prekey not signed")
	}

	@available(iOS 16.0, *)
	func testConversationWithMe() async throws {
		let recip = try PrivateKey.generate()
		let fakeWallet = try PrivateKey.generate()

		let options = ClientOptions(api: ClientOptions.Api(env: .local, isSecure: false))

		try await Client.create(wallet: recip, options: options).publishUserContact()

		let client = try await Client.create(wallet: fakeWallet, options: options)

		let contact = try await client.getUserContact(peerAddress: recip.walletAddress)!

		let privkeybundlev2 = try client.privateKeyBundleV1.toV2()

		let conversations = Conversations(client: client)
		let created = Date()

		let invitationv1 = try InvitationV1.createRandom()

		let invitation = try InvitationV1.createV1(
			sender: try client.privateKeyBundleV1.toV2(),
			recipient: contact.v2.keyBundle,
			created: created,
			invitation: invitationv1
		)

		let sealedInvitation = try await conversations.sendInvitation(
			recipient: privkeybundlev2.getPublicKeyBundle(),
			invitation: invitationv1,
			created: created
		)

		let header = try SealedInvitationHeaderV1(serializedData: invitation.v1.headerBytes)
		let conversation = try ConversationV2.create(client: client, invitation: invitationv1, header: header)

		do {
			try await conversation.send(content: "hello world")
		} catch {
			print("ERROR SENDING \(error)")
		}
	}
}
