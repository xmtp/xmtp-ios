//
//  TextCodec.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

import Foundation
import XMTPProto

let ContentTypeText = ContentTypeID(authorityID: "xmtp.org", typeID: "text", versionMajor: 1, versionMinor: 0)

enum TextCodecError: Error {
	case invalidEncoding, unknownDecodingError
}

struct TextCodec: ContentCodec {
	typealias T = String

	var contentType = ContentTypeText

	func encode(content: String) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeText
		encodedContent.parameters = ["encoding": "UTF-8"]
		encodedContent.content = Data(content.utf8)

		return encodedContent
	}

	func decode(content: EncodedContent) throws -> String {
		if let encoding = content.parameters["encoding"], encoding != "UTF-8" {
			throw TextCodecError.invalidEncoding
		}

		if let contentString = String(data: content.content, encoding: .utf8) {
			return contentString
		} else {
			throw TextCodecError.unknownDecodingError
		}
	}
}

//
// export class TextCodec implements ContentCodec<string> {
//	get contentType(): ContentTypeId {
//		return ContentTypeText
//	}
//
//	encode(content: string): EncodedContent {
//		return {
//			type: ContentTypeText,
//			parameters: { encoding: Encoding.utf8 },
//			content: new TextEncoder().encode(content),
//		}
//	}
//
//	decode(content: EncodedContent): string {
//		const encoding = content.parameters.encoding
//		if (encoding && encoding !== Encoding.utf8) {
//			throw new Error(`unrecognized encoding ${encoding}`)
//		}
//		return new TextDecoder().decode(content.content)
//	}
// }
