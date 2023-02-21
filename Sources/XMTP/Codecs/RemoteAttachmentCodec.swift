//
//  RemoteAttachmentCodec.swift
//
//
//  Created by Pat Nakajima on 2/19/23.
//

import Foundation
import web3
import XMTPProto

public let ContentTypeRemoteAttachment = ContentTypeID(authorityID: "xmtp.org", typeID: "remoteAttachment", versionMajor: 1, versionMinor: 0)

public enum RemoteAttachmentError: Error {
	case invalidURL, v1NotSupported, invalidParameters
}

public struct RemoteAttachment: Codable {
	public var url: String
	public var contentDigest: String
	public var secret: Data
	public var salt: Data
	public var nonce: Data

	public init(url: String, contentDigest: String, secret: Data, salt: Data, nonce: Data) {
		self.url = url
		self.contentDigest = contentDigest
		self.secret = secret
		self.salt = salt
		self.nonce = nonce
	}

	public func content<T>() throws -> T {
		guard let url = URL(string: url) else {
			throw RemoteAttachmentError.invalidURL
		}

		let data = try Data(contentsOf: url)

		let ciphertext = CipherText.with {
			let aes256GcmHkdfSha256 = CipherText.Aes256gcmHkdfsha256.with { aes in
				aes.hkdfSalt = salt
				aes.gcmNonce = nonce
				aes.payload = data
			}

			$0.aes256GcmHkdfSha256 = aes256GcmHkdfSha256
		}

		let decryptedPayloadData = try Crypto.decrypt(secret, ciphertext)
		let decryptedPayload = try EncodedContent(serializedData: decryptedPayloadData)

		// TODO: check digest

		return try decryptedPayload.decoded()
	}
}

public struct RemoteAttachmentCodec: ContentCodec {
	public typealias T = RemoteAttachment

	public init() {}

	public var contentType = ContentTypeRemoteAttachment

	public func encode(content: RemoteAttachment) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		let parameters = [
			"contentDigest": content.contentDigest,
			"secret": content.secret.toHex,
			"salt": content.salt.toHex,
			"nonce": content.nonce.toHex,
		]

		encodedContent.type = ContentTypeRemoteAttachment
		encodedContent.content = Data(content.url.utf8)
		encodedContent.parameters = parameters

		return encodedContent
	}

	public func decode(content: EncodedContent) throws -> RemoteAttachment {
		guard let url = String(data: content.content, encoding: .utf8) else {
			throw RemoteAttachmentError.invalidURL
		}

		guard let contentDigest = content.parameters["contentDigest"],
		      let secretHex = content.parameters["secret"],
		      let secret = secretHex.web3.bytesFromHex,
		      let saltHex = content.parameters["salt"],
		      let salt = saltHex.web3.bytesFromHex,
		      let nonceNex = content.parameters["nonce"],
		      let nonce = nonceNex.web3.bytesFromHex
		else {
			throw RemoteAttachmentError.invalidParameters
		}

		return RemoteAttachment(url: url, contentDigest: contentDigest, secret: Data(secret), salt: Data(salt), nonce: Data(nonce))
	}
}
