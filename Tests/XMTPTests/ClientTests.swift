//
//  ClientTests.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation

import XCTest
@testable import XMTP

struct TestCodec: ContentCodec {
	typealias T = Bool

	var contentType: XMTP.ContentTypeID {
		ContentTypeID(authorityID: "example.com", typeID: "test", versionMajor: 1, versionMinor: 1)
	}

	func encode(content _: Bool) throws -> XMTP.EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeText
		encodedContent.content = Data([0])

		return encodedContent
	}

	func decode(content: XMTP.EncodedContent) throws -> Bool {
		return content.content == Data([0])
	}
}

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

	func testCanHaveCustomCodecs() async throws {
		let fakeWallet = try PrivateKey.generate()
		let client = try await Client.create(account: fakeWallet, options: .init(codecs: [TestCodec()]))
	}
}
