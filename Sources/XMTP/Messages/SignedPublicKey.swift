//
//  SignedPublicKey.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import CryptoKit
import secp256k1
import XMTPProto

typealias SignedPublicKey = Xmtp_MessageContents_SignedPublicKey

extension SignedPublicKey {
	static func fromLegacy(_ legacyKey: PublicKey, signedByWallet: Bool? = false) throws -> SignedPublicKey {
		var signedPublicKey = SignedPublicKey()
		signedPublicKey.keyBytes = try legacyKey.serializedData()
		signedPublicKey.signature = legacyKey.signature

		if signedByWallet == true, signedPublicKey.signature.walletEcdsaCompact.bytes.isEmpty {
			signedPublicKey.signature.walletEcdsaCompact.bytes = signedPublicKey.signature.ecdsaCompact.bytes
			signedPublicKey.signature.walletEcdsaCompact.recovery = signedPublicKey.signature.ecdsaCompact.recovery
		}

		return signedPublicKey
	}

	init(_ publicKey: PublicKey, signature: Signature) throws {
		self.init()
		self.signature = signature

		var unsignedKey = UnsignedPublicKey()
		unsignedKey.createdNs = publicKey.timestamp * 1_000_000
		unsignedKey.secp256K1Uncompressed.bytes = publicKey.secp256K1Uncompressed.bytes

		keyBytes = try unsignedKey.serializedData()
	}

	func verify(key: SignedPublicKey) throws -> Bool {
		if !key.hasSignature {
			return false
		}

		return try signature.verify(signedBy: try PublicKey(key), digest: key.keyBytes)
	}

	func recoverWalletSignerPublicKey() throws -> PublicKey {
		let sigText = Signature.createIdentityText(key: keyBytes)
		let sigHash = try Signature.ethHash(sigText)

		print("RECOVERING \(signature)")
		let pubKeyData = try KeyUtil.recoverPublicKey(message: sigHash, signature: signature.rawData)

		return try PublicKey(pubKeyData)
	}
}
