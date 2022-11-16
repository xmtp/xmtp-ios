//
//  Signature.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1
import XMTPProto

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

	init(ecdsaCompact: secp256k1.Recovery.ECDSASignature? = nil, walletEcdsaCompact: secp256k1.Recovery.ECDSASignature? = nil) {
		self.ecdsaCompact = ecdsaCompact
		self.walletEcdsaCompact = walletEcdsaCompact
	}

	init(_ signature: Xmtp_MessageContents_Signature) throws {
		ecdsaCompact = try secp256k1.Recovery.ECDSASignature(compactRepresentation: signature.ecdsaCompact.bytes, recoveryId: Int32(signature.walletEcdsaCompact.recovery))
		walletEcdsaCompact = try secp256k1.Recovery.ECDSASignature(compactRepresentation: signature.walletEcdsaCompact.bytes, recoveryId: Int32(signature.walletEcdsaCompact.recovery))
	}

	static func ecdsaSignerKey(digest: [UInt8], signature: secp256k1.Recovery.ECDSASignature) -> UnsignedPublicKey? {
		let key = try! secp256k1.Recovery.PublicKey(digest, signature: signature)
		let signature = Signature(ecdsaCompact: signature)

		return PublicKey(createdNs: 0, secp256k1UncompressedBytes: key.rawRepresentation, signature: signature)
	}

	func signerKey(_ key: SignedPublicKey) -> UnsignedPublicKey? {
		if let ecdsaCompact {
			return SignedPrivateKey.signerKey(key: key, signature: ecdsaCompact)
		}

		return nil
	}
}
