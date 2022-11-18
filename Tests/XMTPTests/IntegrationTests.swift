//
//  IntegrationTests.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import secp256k1
import web3
import XCTest
@testable import XMTP

final class IntegrationTests: XCTestCase {
	func testReadSavedKey() async throws {
		let key = try secp256k1.Signing.PrivateKey(rawRepresentation: "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80".web3.bytesFromHex!)
		let alice = PrivateKey(key)

		let idkey = try secp256k1.Signing.PrivateKey(rawRepresentation: "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d".web3.bytesFromHex!)
		let identity = PrivateKey(idkey)

		print("Created keys")

		let authorized = try await alice.createIdentity(identity)
		let authToken = try await authorized.createAuthToken()
		var api = try ApiClient(environment: .local, secure: false)
		api.setAuthToken(authToken)

		print("Set auth token")

		let res = try await api.query(topics: [.userPrivateStoreKeyBundle(authorized.address)])

		print("GOT A RES \(try! res.jsonString())")

		XCTAssertEqual(1, res.envelopes.count)
	}

	func testSaveKey() async throws {
		let alice = try PrivateKey.generate()
		let identity = try PrivateKey.generate()

		let authorized = try await alice.createIdentity(identity)
		let authToken = try await authorized.createAuthToken()

		var api = try ApiClient(environment: .local, secure: false)
		api.setAuthToken(authToken)

		let encryptedBundle = try await authorized.toBundle.encrypted(with: alice)

		var envelope = Envelope()
		envelope.contentTopic = Topic.userPrivateStoreKeyBundle(authorized.address).description
		envelope.timestampNs = UInt64(Date().timeIntervalSince1970 * 1_000_000)
		envelope.message = try encryptedBundle.serializedData()

		try await api.publish(envelopes: [envelope])

		try await Task.sleep(nanoseconds: 1_000_000_000)

		let result = try await api.query(topics: [.userPrivateStoreKeyBundle(authorized.address)])
		XCTAssertEqual(1, result.envelopes.count)
	}
}
