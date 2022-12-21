//
//  CodecTests.swift
//
//
//  Created by Pat Nakajima on 12/21/22.
//

import XCTest
@testable import XMTP

struct NumberCodec: ContentCodec {
	typealias T = Double

	var contentType: XMTP.ContentTypeID {
		ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
	}

	func encode(content _: Double) throws -> XMTP.EncodedContent {
		var content = EncodedContent()
		return content
	}

	func decode(content _: XMTP.EncodedContent) throws -> Double {
		return 0
	}
}

@available(iOS 15, *)
class CodecTests: XCTestCase {
	func testCanRoundTripWithCustomContentType() async throws {
		let fixtures = await fixtures()

		let aliceClient = fixtures.aliceClient!
		let bobClient = fixtures.bobClient!

		let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)
		let bobConversation = try await bobClient.conversations.newConversation(with: fixtures.alice.address)

		try await aliceConversation.send(content: 3.14, codec: NumberCodec())

		let messages = try await bobConversation.messages()
		XCTAssertEqual(messages.count, 1)

		print("MESSAGES: \(messages)")

		if messages.count == 1 {
			let content: Double = messages[0].content as! Double
			XCTAssertEqual(3.14, messages[0].content as! Double)
		}
	}
}
