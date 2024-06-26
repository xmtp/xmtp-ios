//
//  CodecTests.swift
//
//
//  Created by Pat Nakajima on 12/21/22.
//

import XCTest
@testable import XMTPiOS

struct NumberCodec: ContentCodec {
	func shouldPush(content: Double) throws -> Bool {
		return false
	}
	
	func fallback(content: Double) throws -> String? {
		return "pi"
	}
    
	typealias T = Double

	var contentType: XMTPiOS.ContentTypeID {
		ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
	}

	func encode(content: Double, client _: Client) throws -> XMTPiOS.EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
		encodedContent.content = try JSONEncoder().encode(content)

		return encodedContent
	}

	func decode(content: XMTPiOS.EncodedContent, client _: Client) throws -> Double {
		return try JSONDecoder().decode(Double.self, from: content.content)
	}
}

@available(iOS 15, *)
class CodecTests: XCTestCase {
	func testCanRoundTripWithCustomContentType() async throws {
		let fixtures = await fixtures()

		let aliceClient = fixtures.aliceClient!
		let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)

		aliceClient.register(codec: NumberCodec())

		try await aliceConversation.send(content: 3.14, options: .init(contentType: NumberCodec().contentType))

		let messages = try await aliceConversation.messages()
		XCTAssertEqual(messages.count, 1)

		if messages.count == 1 {
			let content: Double = try messages[0].content()
			XCTAssertEqual(3.14, content)
		}
	}

	func testFallsBackToFallbackContentWhenCannotDecode() async throws {
		let fixtures = await fixtures()

		let aliceClient = fixtures.aliceClient!
		let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)

		aliceClient.register(codec: NumberCodec())

		try await aliceConversation.send(content: 3.14, options: .init(contentType: NumberCodec().contentType))

		// Remove number codec from registry
		aliceClient.codecRegistry.codecs.removeValue(forKey: NumberCodec().id)

		let messages = try await aliceConversation.messages()
		XCTAssertEqual(messages.count, 1)

		let content: Double? = try? messages[0].content()
		XCTAssertEqual(nil, content)
		XCTAssertEqual("pi", messages[0].fallbackContent)
	}
	
	func testCanGetPushInfoBeforeDecoded() async throws {
		let fixtures = await fixtures()

		let aliceClient = fixtures.aliceClient!
		let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)

		aliceClient.register(codec: NumberCodec())

		try await aliceConversation.send(content: 3.14, options: .init(contentType: NumberCodec().contentType))

		let messages = try await aliceConversation.messages()
		XCTAssertEqual(messages.count, 1)
		
		let message = try await MessageV2.encode(
			client: aliceClient,
			content: messages[0].encodedContent,
			topic: aliceConversation.topic,
			keyMaterial: Data(aliceConversation.keyMaterial!),
			codec: NumberCodec()
		)
		
		XCTAssertEqual(false, message.shouldPush)
		XCTAssert(!message.senderHmac.isEmpty)

	}
}
