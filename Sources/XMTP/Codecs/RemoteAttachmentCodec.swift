//
//  RemoteAttachmentCodec.swift
//
//
//  Created by Pat Nakajima on 2/19/23.
//

import CryptoKit
import Foundation
import web3
import XMTPProto

public let ContentTypeRemoteAttachment = ContentTypeID(authorityID: "xmtp.org", typeID: "remoteStaticAttachment", versionMajor: 1, versionMinor: 0)

public enum RemoteAttachmentError: Error {
	case invalidURL, v1NotSupported, invalidParameters, invalidDigest, invalidScheme
}

protocol RemoteContentFetcher {
	func fetch(_ url: String) async throws -> Data
}

struct HTTPFetcher: RemoteContentFetcher {
	func fetch(_ url: String) async throws -> Data {
		guard let url = URL(string: url) else {
			throw RemoteAttachmentError.invalidURL
		}

		return try await URLSession.shared.data(from: url).0
	}
}

public struct RemoteAttachment {
	public enum Scheme: String {
		case https = "https://"
	}

	public var url: String
	public var contentDigest: String
	public var secret: Data
	public var salt: Data
	public var nonce: Data
	public var scheme: Scheme
	var fetcher: RemoteContentFetcher

	init(url: String, contentDigest: String, secret: Data, salt: Data, nonce: Data, scheme: Scheme) throws {
		self.url = url
		self.contentDigest = contentDigest
		self.secret = secret
		self.salt = salt
		self.nonce = nonce

		self.scheme = scheme
		self.fetcher = HTTPFetcher()

		try ensureSchemeMatches()
	}

	public init(url: String, encryptedEncodedContent: EncryptedEncodedContent) throws {
		self.url = url
		contentDigest = encryptedEncodedContent.digest
		secret = encryptedEncodedContent.secret
		salt = encryptedEncodedContent.salt
		nonce = encryptedEncodedContent.nonce

		scheme = .https
		fetcher = HTTPFetcher()

		try ensureSchemeMatches()
	}

	func ensureSchemeMatches() throws {
		if !url.hasPrefix(scheme.rawValue) {
			throw RemoteAttachmentError.invalidScheme
		}
	}

	public static func encodeEncrypted<Codec: ContentCodec, T>(content: T, codec: Codec) throws -> EncryptedEncodedContent where Codec.T == T {
		let secret = try Crypto.secureRandomBytes(count: 32)
		let encodedContent = try codec.encode(content: content).serializedData()
		let ciphertext = try Crypto.encrypt(secret, encodedContent)

		return EncryptedEncodedContent(
			secret: secret,
			digest: SHA256.hash(data: ciphertext.aes256GcmHkdfSha256.payload).description,
			salt: ciphertext.aes256GcmHkdfSha256.hkdfSalt,
			nonce: ciphertext.aes256GcmHkdfSha256.gcmNonce,
			payload: ciphertext.aes256GcmHkdfSha256.payload
		)
	}

	public func content() async throws -> EncodedContent {
		let payload = try await fetcher.fetch(url)

		if SHA256.hash(data: payload).description != contentDigest {
			throw RemoteAttachmentError.invalidDigest
		}

		let ciphertext = CipherText.with {
			let aes256GcmHkdfSha256 = CipherText.Aes256gcmHkdfsha256.with { aes in
				aes.hkdfSalt = salt
				aes.gcmNonce = nonce
				aes.payload = payload
			}

			$0.aes256GcmHkdfSha256 = aes256GcmHkdfSha256
		}

		let decryptedPayloadData = try Crypto.decrypt(secret, ciphertext)
		let decryptedPayload = try EncodedContent(serializedData: decryptedPayloadData)

		return decryptedPayload
	}
}

public struct RemoteAttachmentCodec: ContentCodec {
	public typealias T = RemoteAttachment

	public init() {}

	public var contentType = ContentTypeRemoteAttachment

	public func encode(content: RemoteAttachment) throws -> EncodedContent {
		var encodedContent = EncodedContent()

		encodedContent.type = ContentTypeRemoteAttachment
		encodedContent.content = Data(content.url.utf8)
		encodedContent.parameters = [
			"contentDigest": content.contentDigest,
			"secret": content.secret.toHex,
			"salt": content.salt.toHex,
			"nonce": content.nonce.toHex,
			"scheme": "https://"
		]

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
		      let nonce = nonceNex.web3.bytesFromHex,
					let schemeString = content.parameters["scheme"],
					let scheme = RemoteAttachment.Scheme(rawValue: schemeString)
		else {
			throw RemoteAttachmentError.invalidParameters
		}

		return try RemoteAttachment(url: url, contentDigest: contentDigest, secret: Data(secret), salt: Data(salt), nonce: Data(nonce), scheme: scheme)
	}
}
