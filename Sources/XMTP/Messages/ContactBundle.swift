//
//  ContactBundle.swift
//
//
//  Created by Pat Nakajima on 11/23/22.
//

import XMTPProto

typealias ContactBundle = Xmtp_MessageContents_ContactBundle
typealias ContactBundleV1 = Xmtp_MessageContents_ContactBundleV1
typealias ContactBundleV2 = Xmtp_MessageContents_ContactBundleV2

extension ContactBundle {
	static func from(envelope: Envelope) throws -> ContactBundle {
		let data = envelope.message

		var contactBundle = ContactBundle()

		let publicKeyBundle = try PublicKeyBundle(serializedData: data)
		contactBundle.v1.keyBundle = publicKeyBundle

		// It's not a v1 bundle, so serialize the whole thing
		if !contactBundle.v1.keyBundle.identityKey.hasSignature {
			try contactBundle.merge(serializedData: data)
		}

		return contactBundle
	}

	var walletAddress: String? {
		switch version {
		case .v1:
			if let key = try? v1.keyBundle.identityKey.recoverWalletSignerPublicKey() {
				return KeyUtil.generateAddress(from: key.secp256K1Uncompressed.bytes).toChecksumAddress()
			}

			return nil
		case .v2:
			if let key = try? v2.keyBundle.identityKey.recoverWalletSignerPublicKey() {
				return KeyUtil.generateAddress(from: key.secp256K1Uncompressed.bytes).toChecksumAddress()
			}

			return nil
		case .none:
			return nil
		}
	}
}
