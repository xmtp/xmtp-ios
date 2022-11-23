//
//  Wallet.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation

struct Wallet {
	var connection: WalletConnection
	var isConnected: Bool = false

	init(connection: WalletConnection) throws {
		self.connection = connection
	}

	func connect() async throws {
		try await connection.connect()
	}
}

extension Wallet: SigningKey {
	func sign(_ data: Data) async throws -> Signature {
		let signatureData = try await connection.sign(data)

		var signature = Signature()
		signature.walletEcdsaCompact.bytes = signatureData[0 ..< 64]
		signature.walletEcdsaCompact.recovery = UInt32(signatureData[64])

		return signature
	}
}

extension Wallet: WalletConnectionDelegate {
	mutating func didConnect(connection _: WalletConnection) {
		isConnected = true
	}

	mutating func didDisconnect(connection _: WalletConnection) {
		isConnected = false
	}

	mutating func failedToConnect(connection: WalletConnection) {
		print("Failed to connect: \(connection)")
		isConnected = false
	}
}
