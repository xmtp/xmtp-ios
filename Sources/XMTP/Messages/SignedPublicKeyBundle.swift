//
//  SignedPublicKeyBundle.swift
//
//
//  Created by Pat Nakajima on 11/23/22.
//

import XMTPProto

typealias SignedPublicKeyBundle = Xmtp_MessageContents_SignedPublicKeyBundle

extension SignedPublicKeyBundle {
	init(_ publicKeyBundle: PublicKeyBundle) throws {
		self.init()

		let signedByWallet = publicKeyBundle.identityKey.signature.walletEcdsaCompact.isInitialized
		identityKey = try SignedPublicKey.fromLegacy(publicKeyBundle.identityKey, signedByWallet: signedByWallet)
		identityKey.signature = publicKeyBundle.identityKey.signature
		preKey = try SignedPublicKey.fromLegacy(publicKeyBundle.preKey)
	}

	var walletAddress: String {
		get throws {
			// swiftlint:disable no_optional_try
			if let address = try? identityKey.recoverWalletSignerPublicKey().walletAddress {
				// swiftlint:enable no_optional_try
				return address
			}

			throw PublicKeyError.addressNotFound
		}
	}
}
