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

	func encode(content: Double) throws -> XMTP.EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
		encodedContent.content = try JSONEncoder().encode(content)

		return encodedContent
	}

	func decode(content: XMTP.EncodedContent) throws -> Double {
		return try JSONDecoder().decode(Double.self, from: content.content)
	}
}

@available(iOS 15, *)
class CodecTests: XCTestCase {
	func testCanRoundTripWithCustomContentType() async throws {
		Client.register(codec: NumberCodec())

		let fixtures = await fixtures()

		let aliceClient = fixtures.aliceClient!
		let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)

		try await aliceConversation.send(content: 3.14, codec: NumberCodec())

		let messages = try await aliceConversation.messages()
		XCTAssertEqual(messages.count, 1)

		if messages.count == 1 {
			let content: Double = try messages[0].content(as: Double.self)
			XCTAssertEqual(3.14, content)
		}
	}

	func testFallsBackToFallbackContentWhenCannotDecode() async throws {
		let fixtures = await fixtures()

		let aliceClient = fixtures.aliceClient!
		let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)

		try await aliceConversation.send(content: 3.14, codec: NumberCodec(), fallback: "pi")

		// Remove number codec from registry
		Client.codecRegistry.codecs.removeValue(forKey: NumberCodec().id)

		let messages = try await aliceConversation.messages()
		XCTAssertEqual(messages.count, 1)

		let content: Double? = try? messages[0].content(as: Double.self)
		XCTAssertEqual(nil, content)
		XCTAssertEqual("pi", messages[0].fallbackContent)
	}
}
