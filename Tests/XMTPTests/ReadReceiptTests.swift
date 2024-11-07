import Foundation
import XCTest

@testable import XMTPiOS

@available(iOS 15, *)
class ReadReceiptTests: XCTestCase {
	func testCanUseReadReceiptCodec() async throws {
		let fixtures = try await fixtures()
		fixtures.alixClient.register(codec: ReadReceiptCodec())

		let conversation = try await fixtures.alixClient.conversations
			.newConversation(with: fixtures.boClient.address)

		try await conversation.send(text: "hey alix 2 bo")

		let read = ReadReceipt()

		try await conversation.send(
			content: read,
			options: .init(contentType: ContentTypeReadReceipt)
		)

		let updatedMessages = try await conversation.messages()

		let message = try await conversation.messages()[0]
		let contentType: String = message.encodedContent.type.typeID
		XCTAssertEqual("readReceipt", contentType)
	}
}
