//
//  PublicKey.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1
import WalletConnectSwift
import web3
import XMTPProto

enum PublicKeyError: Error {
	case unsigned
	case notSignedByWallet
	case invalidKeySignature
}

// LEGACY: PublicKey optionally signed with another trusted key pair or a wallet.
// PublicKeys can be generated through PrivateKey.generate()
struct PublicKey: UnsignedPublicKey {
	var createdNs: Int = 0
	var secp256k1UncompressedBytes: Data
	var signature: Signature?

	mutating func signWithWallet(wallet: WalletConnectSwift.Client) async throws {
		let sigString = try await WalletSigner.sign(wallet: wallet, message: WalletSigner.identitySigRequestText(keyBytes: secp256k1UncompressedBytes))

		print("GOT THIS SIG STRING (\(sigString.count) \(sigString)")
		let sigParts = try WalletSigner.signatureParts(from: sigString)

		let r = try sigParts.r.bytes
		let s = try sigParts.s.bytes
		let sigBytes: [UInt8] = r + s

		let sig = try secp256k1.Recovery.ECDSASignature(compactRepresentation: sigBytes, recoveryId: Int32(sigParts.recoveryParam))

		signature = Signature(walletEcdsaCompact: sig)
	}

	func walletSignatureAddress() throws -> String {
		if signature?.walletEcdsaCompact == nil {
			throw PublicKeyError.notSignedByWallet
		}

		guard let pk = signerKey() else {
			throw PublicKeyError.invalidKeySignature
		}

		return pk.getEthereumAddress()
	}

	func signerKey() -> UnsignedPublicKey? {
		guard let signature, let sigBytes = signature.walletEcdsaCompact?.bytes else {
			return nil
		}

		return WalletSigner.signerKey(signature: signature)
	}
}
