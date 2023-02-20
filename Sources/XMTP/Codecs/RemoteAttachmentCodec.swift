//
//  RemoteAttachmentCodec.swift
//
//
//  Created by Pat Nakajima on 2/19/23.
//

import Foundation
import XMTPProto

public let ContentTypeRemoteAttachment = ContentTypeID(authorityID: "xmtp.org", typeID: "remoteAttachment", versionMajor: 1, versionMinor: 0)

public enum RemoteAttachmentError: Error {
	case invalidURL
}

public struct RemoteAttachment: Codable {
	var url: String

	func envelope() async throws -> Envelope {
		guard let url = URL(string: url) else {
			throw RemoteAttachmentError.invalidURL
		}

		let data = try Data(contentsOf: url)
		let envelope = try Envelope(serializedData: data)

		return envelope
	}
}

struct RemoteAttachmentCodec: ContentCodec {
	typealias T = RemoteAttachment

	var contentType = ContentTypeRemoteAttachment

	func encode(content: RemoteAttachment) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeRemoteAttachment
		encodedContent.content = Data(content.url.utf8)

		return encodedContent
	}

	func decode(content: EncodedContent) throws -> RemoteAttachment {
		guard let url = String(data: content.content, encoding: .utf8) else {
			throw RemoteAttachmentError.invalidURL
		}

		return RemoteAttachment(url: url)
	}
}
