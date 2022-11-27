//
//  PrivateKeyBundleV2.swift
//  
//
//  Created by Pat Nakajima on 11/26/22.
//

import XMTPProto
import Foundation

typealias PrivateKeyBundleV2 = Xmtp_MessageContents_PrivateKeyBundleV2

extension PrivateKeyBundleV2 {
	func sharedSecret(peer: SignedPublicKeyBundle, myPreKey: SignedPublicKey, isRecipient: Bool) throws -> Data {
		var dh1: Data
		var dh2: Data
		var preKey: SignedPrivateKey

		if isRecipient {
			preKey = try findPreKey(myPreKey)
			dh1 = try preKey.sharedSecret(peer.identityKey)
			dh2 = try identityKey.sharedSecret(peer.preKey)
		} else {
			preKey = try findPreKey(myPreKey)
			dh1 = try identityKey.sharedSecret(peer.preKey)
			dh2 = try preKey.sharedSecret(peer.identityKey)
		}

		let dh3 = try preKey.sharedSecret(peer.preKey)

		let secret = dh1 + dh2 + dh3

		return secret
	}

	func findPreKey(_ myPreKey: SignedPublicKey) throws -> SignedPrivateKey {
		for preKey in self.preKeys {
			if preKey.matches(myPreKey) {
				return preKey
			}
		}

		throw PrivateKeyBundleError.noPreKeyFound
	}

	func getPublicKeyBundle() -> SignedPublicKeyBundle {
		var publicKeyBundle = SignedPublicKeyBundle()

		publicKeyBundle.identityKey = identityKey.publicKey
		publicKeyBundle.preKey = preKeys[0].publicKey

		return publicKeyBundle
	}
}
