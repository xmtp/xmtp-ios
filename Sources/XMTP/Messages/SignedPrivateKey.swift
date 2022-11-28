//
//  SignedPrivateKey.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import Foundation
import secp256k1
import XMTPProto

typealias SignedPrivateKey = Xmtp_MessageContents_SignedPrivateKey

extension SignedPrivateKey {
	static func fromLegacy(_ key: PrivateKey, signedByWallet: Bool? = false) throws -> SignedPrivateKey {
		var signedPrivateKey = SignedPrivateKey()

		signedPrivateKey.createdNs = key.timestamp * 1_000_000
		signedPrivateKey.secp256K1.bytes = key.secp256K1.bytes
		signedPrivateKey.publicKey = try SignedPublicKey.fromLegacy(key.publicKey, signedByWallet: signedByWallet)

		return signedPrivateKey
	}

	func matches(_ signedPublicKey: SignedPublicKey) -> Bool {
		do {
			let deserializedPublic = try UnsignedPublicKey(serializedData: publicKey.keyBytes)
			let deserializedSigned = try UnsignedPublicKey(serializedData: signedPublicKey.keyBytes)

			return deserializedPublic.secp256K1Uncompressed.bytes == deserializedSigned.secp256K1Uncompressed.bytes
		} catch {
			print("Error in matchces \(error)")
			return false
		}
	}

	func sharedSecret(_ peer: SignedPublicKey) throws -> Data {
		let publicKey = try UnsignedPublicKey(serializedData: peer.keyBytes)

		return try sharedSecret(publicKey.secp256K1Uncompressed.bytes)
	}

	func sharedSecret(_ peer: PublicKey) throws -> Data {
		return try sharedSecret(peer.secp256K1Uncompressed.bytes)
	}

	private func sharedSecret(_ publicKeyBytes: Data) throws -> Data {
		var privateKey: secp256k1.KeyAgreement.PrivateKey?
		var publicKey: secp256k1.KeyAgreement.PublicKey?
		var sharedSecret: SharedSecret?

		do {
			privateKey = try secp256k1.KeyAgreement.PrivateKey(rawRepresentation: secp256K1.bytes, format: .uncompressed)
		} catch {
			fatalError("error with private key: \(error)")
		}

		do {
			publicKey = try secp256k1.KeyAgreement.PublicKey(rawRepresentation: publicKeyBytes, format: .uncompressed)
		} catch {
			fatalError("error with public ey \(publicKeyBytes.count): \(error)")
		}

		do {
			if let privateKey, let publicKey {
				sharedSecret = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)
			}

			return Data(sharedSecret?.bytes ?? [])
		} catch {
			fatalError("Erro generating shared secret \(error)")
		}

		return Data()
	}
}
