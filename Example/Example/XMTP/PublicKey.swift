//
//  PublicKey.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import secp256k1
import XMTPProto
import WalletConnectSwift

enum PublicKeyError: Error {
	case unsigned
}

// LEGACY: PublicKey optionally signed with another trusted key pair or a wallet.
// PublicKeys can be generated through PrivateKey.generate()
struct PublicKey: UnsignedPublicKey {
	var createdNs: Int
	var secp256k1UncompressedBytes: [UInt8]
	var signature: Signature?

	func bytesToSign() throws -> [UInt8] {
		var protoPublicKey = Xmtp_MessageContents_PublicKey()
		var uncompressed = Xmtp_MessageContents_PublicKey.Secp256k1Uncompressed()
		uncompressed.bytes = Data(secp256k1UncompressedBytes)

		protoPublicKey.timestamp = UInt64(createdNs)
		protoPublicKey.secp256K1Uncompressed = uncompressed
		return try protoPublicKey.serializedData().bytes
	}

	mutating func signWithWallet(wallet: WalletConnectSwift.Client) async throws {
		let sigString = try await WalletSigner.sign(wallet: wallet, message: WalletSigner.identitySigRequestText(keyBytes: secp256k1UncompressedBytes))

		print("GOT THIS SIG STRING (\(sigString.count) \(sigString)")
		let sigParts = try WalletSigner.signatureParts(from: sigString)

		let r = try sigParts.r.bytes
		let s = try sigParts.s.bytes
		let sigBytes: [UInt8] = r + s

		let sig = try secp256k1.Recovery.ECDSASignature(compactRepresentation: sigBytes, recoveryId: Int32(sigParts.recoveryParam))

		self.signature = Signature(walletEcdsaCompact: sig)
	}

	func walletSignatureAddress() -> String {
		// FIXME: todo
		""
	}
}
