//
//  PrivateKey.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import secp256k1
import web3
import XMTPProto

typealias PrivateKey = Xmtp_MessageContents_PrivateKey

enum PrivateKeyError: Error {
	case invalidSignatureText, invalidPrefix
}

extension PrivateKey: PrivateKeySigner {
	var signingBytes: Data {
		secp256K1.bytes
	}
}

extension PrivateKey {
	init(_ secpkey: secp256k1.Signing.PrivateKey) {
		self.init()
		timestamp = UInt64(Date().timeIntervalSince1970 * 1_000_000)

		var keyData = Secp256k1()
		keyData.bytes = secpkey.rawRepresentation
		secp256K1 = keyData

		var publicKey = PublicKey()
		var publicSecp = Xmtp_MessageContents_PublicKey.Secp256k1Uncompressed()
		publicSecp.bytes = secpkey.publicKey.rawRepresentation
		publicKey.secp256K1Uncompressed = publicSecp
		publicKey.timestamp = timestamp

		self.publicKey = publicKey
	}

	static func generate() throws -> PrivateKey {
		let secpkey = try secp256k1.Signing.PrivateKey(format: .uncompressed)

		return PrivateKey(secpkey)
	}

	// TODO: Move this to protocol
	func sign(key: UnsignedPublicKey) async throws -> SignedPublicKey {
		let bytes = key.secp256K1Uncompressed.bytes
		let digest = SHA256Digest([UInt8](bytes))
		let signature = try await sign(digest: digest.bytes)

		var signedPublicKey = SignedPublicKey()
		signedPublicKey.signature = signature
		signedPublicKey.keyBytes = bytes

		return signedPublicKey
	}

	// TODO: Move this to protocol
	func sign(message: String) async throws -> Signature {
		let prefix = "\u{19}Ethereum Signed Message:\n\(message.count)"
		guard var data = prefix.data(using: .utf8) else {
			throw PrivateKeyError.invalidPrefix
		}

		data.append(message.data(using: .utf8)!)

		let digest = data.web3.keccak256

		return try await sign(digest: digest)
	}

	// TODO: Move this to protocol
	func createIdentity(_ key: PrivateKey) async throws -> AuthorizedIdentity {
		let signatureText = Signature.createIdentityText(key: try key.publicKey.serializedData())
		let signature = try await sign(message: signatureText)

		let address = KeyUtil.generateAddress(from: publicKey.secp256K1Uncompressed.bytes).toChecksumAddress()

		var signedPrivateKey = SignedPrivateKey()
		signedPrivateKey.secp256K1.bytes = secp256K1.bytes
		signedPrivateKey.createdNs = timestamp
		signedPrivateKey.publicKey = SignedPublicKey()
		signedPrivateKey.publicKey.signature = signature
		signedPrivateKey.publicKey.keyBytes = try UnsignedPublicKey(publicKey).serializedData()

		return AuthorizedIdentity(address: address, publicKey: signedPrivateKey.publicKey, privateKey: key)
	}
}
