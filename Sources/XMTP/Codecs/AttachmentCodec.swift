//
//  AttachmentCodec.swift
//
//
//  Created by Pat on 2/14/23.
//

import Foundation
import XMTPProto

let ContentTypeAttachment = ContentTypeID(authorityID: "xmtp.org", typeID: "attachment", versionMajor: 1, versionMinor: 0)

enum AttachmentCodecError: Error {
	case invalidMimeType, unknownDecodingError
}

struct Attachment: Codable {
	var mimeType: String
	var data: Data
}

struct AttachmentCodec: ContentCodec {
	typealias T = Attachment

	var contentType = ContentTypeAttachment

	func encode(content: Attachment) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeAttachment
		encodedContent.parameters = ["mimeType": content.mimeType]
		encodedContent.content = content.data

		return encodedContent
	}

	func decode(content: EncodedContent) throws -> Attachment {
		guard let mimeType = content.parameters["mimeType"] else {
			throw AttachmentCodecError.invalidMimeType
		}

		let attachment = Attachment(mimeType: mimeType, data: content.content)

		return attachment
	}
}
