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
		_ = try await Client.create(account: fakeWallet)
	}

	func testHasPrivateKeyBundleV1() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet)

		XCTAssertEqual(1, client.privateKeyBundleV1.preKeys.count)

		let preKey = client.privateKeyBundleV1.preKeys[0]

		XCTAssert(preKey.publicKey.hasSignature, "prekey not signed")
	}

	func testCanBeCreatedWithV2Bundle() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet)

		let bundleV2 = client.keys
		let clientFromV2Bundle = try Client.from(bundle: bundleV2)

		XCTAssertEqual(client.address, clientFromV2Bundle.address)
		XCTAssertEqual(client.privateKeyBundleV1.identityKey, clientFromV2Bundle.privateKeyBundleV1.identityKey)
		XCTAssertEqual(client.privateKeyBundleV1.preKeys, clientFromV2Bundle.privateKeyBundleV1.preKeys)
	}
}
