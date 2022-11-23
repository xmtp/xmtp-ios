//
//  IntegrationTests.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import secp256k1
import WalletConnectSwift
import web3
import XCTest
@testable import XMTP

class CallbackyConnection: WCWalletConnection {
	var onConnect: (() -> Void)?

	override func client(_ client: WalletConnectSwift.Client, didConnect session: WalletConnectSwift.Session) {
		super.client(client, didConnect: session)
		onConnect?()
	}
}

@available(iOS 16, *)
final class IntegrationTests: XCTestCase {
	func testSaveKey() async throws {
		throw XCTSkip("integration only")
		let alice = try PrivateKey.generate()
		let identity = try PrivateKey.generate()

		let authorized = try await alice.createIdentity(identity)

		let authToken = try await authorized.createAuthToken()

		var api = try ApiClient(environment: .local, secure: false)
		api.setAuthToken(authToken)

		let encryptedBundle = try await authorized.toBundle.encrypted(with: alice)

		var envelope = Envelope()
		envelope.contentTopic = Topic.userPrivateStoreKeyBundle(authorized.address).description
		envelope.timestampNs = UInt64(Date().millisecondsSinceEpoch) * 1_000_000
		envelope.message = try encryptedBundle.serializedData()

		try await api.publish(envelopes: [envelope])

		try await Task.sleep(nanoseconds: 2_000_000_000)

		let result = try await api.query(topics: [.userPrivateStoreKeyBundle(authorized.address)])
		XCTAssert(result.envelopes.count == 1)
	}

	func testWalletSaveKey() async throws {
		throw XCTSkip("integration only")

		let connection = CallbackyConnection()
		let wallet = try Wallet(connection: connection)

		let expectation = expectation(description: #function)

		connection.onConnect = {
			expectation.fulfill()
		}

		guard let url = connection.walletConnectURL?.absoluteString else {
			XCTFail("No WC URL")
			return
		}

		let safariURL = "wc://wc?uri=\(url)"

		print("Open in mobile safari: \(safariURL)")
		try await connection.connect()

		wait(for: [expectation], timeout: 60)

		let digest = "Hello world".data(using: .utf8)!

		let signature = try await wallet.sign(digest)

		let recoverDigest = try Signature.ethHash("Hello world")
		let publicKey = try KeyUtil.recoverPublicKey(message: recoverDigest, signature: signature.rawData)
		let address = KeyUtil.generateAddress(from: publicKey)

		XCTAssertEqual(address, "0x1F935A71f5539fa0eEaa71136Aef39Ab7c64520f") // fancypat.eth
		XCTAssert(signature.walletEcdsaCompact.bytes.count > 1)
	}
}
