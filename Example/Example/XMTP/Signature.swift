//
//  Signature.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1

protocol KeySigner {
	func signKey(key: UnsignedPublicKey) async -> SignedPublicKey
}

enum SignedPrivateKey {
	static func signerKey(key: SignedPublicKey, signature: secp256k1.Recovery.ECDSASignature) -> UnsignedPublicKey? {
		let digest = SHA256Digest(try! key.bytesToSign())
		return Signature.ecdsaSignerKey(digest: digest.bytes, signature: signature)
	}
}

struct Signature {
	var ecdsaCompact: secp256k1.Recovery.ECDSASignature?
	var walletEcdsaCompact: secp256k1.Recovery.ECDSASignature?

	static func ecdsaSignerKey(digest: [UInt8], signature: secp256k1.Recovery.ECDSASignature) -> UnsignedPublicKey? {
		let key = try! secp256k1.Recovery.PublicKey(digest, signature: signature)
		return PublicKey(createdNs: 0, secp256k1UncompressedBytes: key.rawRepresentation.bytes)
	}

	func signerKey(_ key: SignedPublicKey) -> UnsignedPublicKey? {
		if let ecdsaCompact {
			return SignedPrivateKey.signerKey(key: key, signature: ecdsaCompact)
		}

		return nil
	}
}
