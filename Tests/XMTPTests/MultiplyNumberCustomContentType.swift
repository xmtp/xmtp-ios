//
//  CodecTests.swift
//
//
//  Created by Pat Nakajima on 12/21/22.
//

import XCTest
@testable import XMTP


public struct SingleNumberCodec: ContentCodec {
	
    
	public typealias T = Double

	public var contentType: ContentTypeID {
		ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
	}

	public func encode(content: Double, client _: Client) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
		encodedContent.content = try JSONEncoder().encode(content)

		return encodedContent
	}

	public func decode(content: EncodedContent, client _: Client) throws -> Double {
		let decoded = try JSONDecoder().decode(Double.self, from: content.content)
		return decoded * 2
	}
    public func fallback(content: Double) throws -> String? {
		return "SingleNumberCodec is not supported"
	}
}


public struct MultiplyNumbers {
    public var num1: Double
    public var num2: Double
    public var result: Double?

    public init(num1: Double, num2: Double, result: Double? = nil) {
        self.num1 = num1
        self.num2 = num2
        self.result = result
    }
}

public struct MultiplyNumbersCodec: ContentCodec {
	public typealias T = MultiplyNumbers

	public var contentType: ContentTypeID {
		ContentTypeID(authorityID: "example.com", typeID: "number", versionMajor: 1, versionMinor: 1)
	}

    public func encode(content: MultiplyNumbers, client: Client) throws -> EncodedContent {
        var encodedContent = EncodedContent()
        encodedContent.type = contentType
        encodedContent.parameters["num1"] = String(content.num1)
        encodedContent.parameters["num2"] = String(content.num2)
        return encodedContent
    }

	public func decode(content: EncodedContent, client _: Client) throws -> MultiplyNumbers {
        guard let num1Str = content.parameters["num1"], let num1 = Double(num1Str),
              let num2Str = content.parameters["num2"], let num2 = Double(num2Str) else {
            throw CodecError.invalidContent
        }
        return MultiplyNumbers(num1: num1, num2: num2, result: num1 * num2)
    }
    
    public func fallback(content: MultiplyNumbers) throws -> String? {
		return "MultiplyNumbersCodec is not supported"
	}
}

@available(iOS 15, *)
class MultiplyNumberCustomContentType: XCTestCase {
    func testCanRoundTripWithMultiplyNumbersCodec() async throws {
        let fixtures = await fixtures()

        let aliceClient = fixtures.aliceClient!
        let aliceConversation = try await aliceClient.conversations.newConversation(with: fixtures.bob.address)

        aliceClient.register(codec: MultiplyNumbersCodec())

        let multiplyNumbers = MultiplyNumbers(num1: 3, num2: 2)
        try await aliceConversation.send(content: multiplyNumbers, options: .init(contentType: MultiplyNumbersCodec().contentType))

        let messages = try await aliceConversation.messages()
        XCTAssertEqual(messages.count, 1)

        if messages.count == 1 {
            let content: MultiplyNumbers = try messages[0].content()
            XCTAssertEqual(6, content.result)
        }
    }

}
