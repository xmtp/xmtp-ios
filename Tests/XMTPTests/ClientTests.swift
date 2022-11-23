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
	}
}
