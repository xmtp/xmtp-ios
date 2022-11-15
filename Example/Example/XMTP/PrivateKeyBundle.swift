//
//  PrivateKeyBundle.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import Foundation
import WalletConnectSwift

protocol PrivateKeyBundle {}

struct PrivateKeyBundleV1: PrivateKeyBundle {
	var identityKey: PrivateKey
	var preKeys: [PrivateKey] = []
	let version = 1

	static func generate(wallet: WalletConnectSwift.Client) async throws -> PrivateKeyBundleV1 {
		var identityKey = PrivateKey.generate()

		try await identityKey.publicKey.signWithWallet(wallet: wallet)

		var bundle = PrivateKeyBundleV1(identityKey: identityKey)
		try await bundle.addPreKey()

		return bundle
	}

	mutating func addPreKey() async throws {
		var preyKey = PrivateKey.generate()
		try await identityKey.signKey(publicKey: &preyKey.publicKey)
		preKeys.insert(preyKey, at: 0)
	}
}

struct PrivateKeyBundleV2: PrivateKeyBundle {
	static func fromLegacyBundle(_: PrivateKeyBundleV1) -> PrivateKeyBundleV2 {
		return PrivateKeyBundleV2()
	}
}
