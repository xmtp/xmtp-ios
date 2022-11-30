//
//  PrivateKeyBundleV2.swift
//
//
//  Created by Pat Nakajima on 11/26/22.
//

import Foundation
import secp256k1
import XMTPProto

typealias PrivateKeyBundleV2 = Xmtp_MessageContents_PrivateKeyBundleV2

extension PrivateKeyBundleV2 {
	func sharedSecret(peer: SignedPublicKeyBundle, myPreKey: SignedPublicKey, isRecipient: Bool) throws -> Data {
		var dh1: Data
		var dh2: Data
		var preKey: SignedPrivateKey

		if isRecipient {
			preKey = try findPreKey(myPreKey)
			dh1 = try sharedSecret(private: preKey.secp256K1.bytes, public: peer.identityKey.secp256K1Uncompressed.bytes)
			dh2 = try sharedSecret(private: identityKey.secp256K1.bytes, public: peer.preKey.secp256K1Uncompressed.bytes)
		} else {
			preKey = try findPreKey(myPreKey)
			dh1 = try sharedSecret(private: identityKey.secp256K1.bytes, public: peer.preKey.secp256K1Uncompressed.bytes)
			dh2 = try sharedSecret(private: preKey.secp256K1.bytes, public: peer.identityKey.secp256K1Uncompressed.bytes)
		}

		let dh3 = try sharedSecret(private: preKey.secp256K1.bytes, public: peer.preKey.secp256K1Uncompressed.bytes)

		print("DH1 \(dh1.count)")
		print("DH2 \(dh2.count)")
		print("DH3 \(dh3.count)")

		let secret = dh1 + dh2 + dh3

		return secret
	}

	func sharedSecret(private privateData: Data, public publicData: Data) throws -> Data {
		let privateKey = try secp256k1.KeyAgreement.PrivateKey(rawRepresentation: privateData, format: .uncompressed)
		let publicKey = try secp256k1.KeyAgreement.PublicKey(rawRepresentation: publicData, format: .uncompressed)

		let agreement = try privateKey.sharedSecretFromKeyAgreement(with: publicKey)

		return Data(agreement.bytes)
	}

	func findPreKey(_ myPreKey: SignedPublicKey) throws -> SignedPrivateKey {
		for preKey in preKeys {
			if preKey.matches(myPreKey) {
				return preKey
			}
		}

		throw PrivateKeyBundleError.noPreKeyFound
	}

	func getPublicKeyBundle() -> SignedPublicKeyBundle {
		var publicKeyBundle = SignedPublicKeyBundle()

		publicKeyBundle.identityKey = identityKey.publicKey
		publicKeyBundle.identityKey.signature = identityKey.publicKey.signature
		publicKeyBundle.preKey = preKeys[0].publicKey

		return publicKeyBundle
	}
}
