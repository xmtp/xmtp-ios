//
//  TextCodec.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation

let ContentTypeText = ContentTypeID(authorityID: "xmtp.org", typeID: "text", versionMajor: 1, versionMinor: 0)

struct TextCodec: ContentCodec {
	typealias T = String

	let contentType = ContentTypeText

	func encode(content: String, registry _: CodecRegistry) throws -> EncodedContent {
		EncodedContent(
			type: ContentTypeText,
			parameters: ["encoding": String.Encoding.utf8.description], // Don't love this
			content: content.utf8.map { $0 }
		)
	}

	func decode(content: EncodedContent, registry _: CodecRegistry) throws -> String {
		let encoding = content.parameters["encoding"]

		guard let encoding, encoding == String.Encoding.utf8.description else {
			throw CodecError.unrecognizedEncoding(encoding.debugDescription)
		}

		guard let result = String(bytes: content.content, encoding: .utf8) else {
			throw CodecError.decodingError("could not decode text")
		}

		return result
	}
}
