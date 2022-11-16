//
//  UnsignedPublicKey.swift
//  Example
//
//  Created by Pat Nakajima on 11/14/22.
//

import Foundation
import secp256k1
import web3
import XMTPProto

protocol UnsignedPublicKey {
	var createdNs: Int { get }
	var secp256k1UncompressedBytes: Data { get }
}

extension UnsignedPublicKey {
	func bytesToSign() throws -> [UInt8] {
		var protoPublicKey = Xmtp_MessageContents_PublicKey()
		var uncompressed = Xmtp_MessageContents_PublicKey.Secp256k1Uncompressed()
		uncompressed.bytes = Data(secp256k1UncompressedBytes)

		protoPublicKey.timestamp = UInt64(createdNs / 1_000_000)
		protoPublicKey.secp256K1Uncompressed = uncompressed
		return try protoPublicKey.serializedData().bytes
	}

	func getEthereumAddress() -> String {
		let publicKey = Data(secp256k1UncompressedBytes)
		let hash = publicKey.web3.keccak256
		let address = hash.subdata(in: 12 ..< hash.count)
		return address.web3.hexString
	}
}
