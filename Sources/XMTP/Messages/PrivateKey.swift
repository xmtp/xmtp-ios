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
	case invalidSignatureText, invalidPrefix, invalidSignature
}

extension PrivateKey: SigningKey {
	func sign(_ data: Data) async throws -> Signature {
		let signingKey = try secp256k1.Signing.PrivateKey(rawRepresentation: secp256K1.bytes, format: .uncompressed)
		let signatureData = try signingKey.ecdsa.recoverableSignature(for: data)
		let compact = try signatureData.compactRepresentation

		var signature = Signature()
		signature.ecdsaCompact.bytes = compact.signature
		signature.ecdsaCompact.recovery = UInt32(compact.recoveryId)

		return signature
	}
}

extension PrivateKey {
	// Easier conversion from the secp256k1 library's Private keys to our proto type.
	init(_ secpkey: secp256k1.Signing.PrivateKey) {
		self.init()
		timestamp = UInt64(Date().millisecondsSinceEpoch)

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

	var walletAddress: String {
		KeyUtil.generateAddress(from: publicKey.secp256K1Uncompressed.bytes).value
	}

	func sign(key: UnsignedPublicKey) async throws -> SignedPublicKey {
		let bytes = key.secp256K1Uncompressed.bytes
		let digest = SHA256Digest([UInt8](bytes))
		let signature = try await sign(Data(digest.bytes))

		var signedPublicKey = SignedPublicKey()
		signedPublicKey.signature = signature
		signedPublicKey.keyBytes = bytes

		return signedPublicKey
	}
}
