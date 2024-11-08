import Foundation
import XCTest

@testable import XMTPiOS

@available(iOS 15, *)
class AttachmentsTests: XCTestCase {
	func testCanUseAttachmentCodec() async throws {
		// swiftlint:disable force_try
		let iconData = Data(
			base64Encoded: Data(
				"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"
					.utf8))!
		let fixtures = try await fixtures()
		let conversation = try await fixtures.alixClient.conversations
			.newConversation(with: fixtures.boClient.address)

		fixtures.alixClient.register(codec: AttachmentCodec())

		try await conversation.send(
			content: Attachment(
				filename: "icon.png", mimeType: "image/png", data: iconData),
			options: .init(contentType: ContentTypeAttachment))
		let messages = try await conversation.messages()

		XCTAssertEqual(2, messages.count)

		let message = messages[0]
		let attachment: Attachment = try message.content()
		XCTAssertEqual("icon.png", attachment.filename)
		XCTAssertEqual("image/png", attachment.mimeType)
	}
}
