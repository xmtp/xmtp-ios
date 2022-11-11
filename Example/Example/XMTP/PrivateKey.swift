//
//  PrivateKey.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1

// LEGACY: PrivateKey represents a secp256k1 private key.
struct PrivateKey {
	var timestamp: Int
	var secp256k1Bytes: [UInt8]
	var publicKey: PublicKey

	static func generate() -> PrivateKey {
		let secp256k1Key = try! secp256k1.KeyAgreement.PrivateKey()
		let timestamp = Int((Date().timeIntervalSince1970 * 1000.0).rounded())
		let publicKey = PublicKey(createdNs: timestamp, secp256k1UncompressedBytes: secp256k1Key.publicKey.rawRepresentation.bytes)

		return PrivateKey(timestamp: timestamp, secp256k1Bytes: secp256k1Key.rawRepresentation.bytes, publicKey: publicKey)
	}

	func sign(digest: [UInt8]) throws -> Signature {
		let key = try secp256k1.Signing.PrivateKey(rawRepresentation: secp256k1Bytes)
		let res = try key.ecdsa.recoverableSignature(for: digest)
		return Signature(walletEcdsaCompact: res)
	}

	@discardableResult func signKey(publicKey: inout PublicKey) async throws -> PublicKey {
		let bytesToSign = try publicKey.bytesToSign()
		let digest = SHA256Digest(bytesToSign).bytes
		publicKey.signature = try sign(digest: digest)
		return publicKey
	}
}
