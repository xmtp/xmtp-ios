//
//  MessageTests.swift
//
//
//  Created by Pat Nakajima on 11/27/22.
//

import XCTest
@testable import XMTP

@available(iOS 16.0, *)
class MessageTests: XCTestCase {
	// FIXME: This is flakey, sometimes it passes, sometimes not.
	func testFullyEncodesDecodesMessages() async throws {
		let aliceWallet = try PrivateKey.generate()
		let bobWallet = try PrivateKey.generate()

		let alice = try await PrivateKeyBundleV1.generate(wallet: aliceWallet)
		let bob = try await PrivateKeyBundleV1.generate(wallet: bobWallet)

		let alicePub = alice.toPublicKeyBundle()

		let content = Data("Yo!".utf8)
		let message1 = try MessageV1.encode(
			sender: alice,
			recipient: bob.toPublicKeyBundle(),
			message: content,
			timestamp: Date()
		).v1

		XCTAssertEqual(aliceWallet.walletAddress, try alice.identityKey.publicKey.recoverWalletSignerPublicKey().walletAddress)

		XCTAssertEqual(aliceWallet.walletAddress, message1.senderAddress)
		XCTAssertEqual(bobWallet.walletAddress, message1.recipientAddress)

		let decrypted = try message1.decrypt(with: alice)
		XCTAssertEqual(decrypted, content)

		let message2 = try MessageV1(serializedData: try message1.serializedData())
		let message2Decrypted = try message2.decrypt(with: alice)
		XCTAssertEqual(message2.senderAddress, aliceWallet.walletAddress)
		XCTAssertEqual(message2.recipientAddress, bobWallet.walletAddress)
	}
}
