//
//  WalletConnection.swift
//
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation

import Foundation
import WalletConnectSwift
import web3

enum WalletConnectionError: Error {
	case walletConnectURL
	case noSession
	case noAddress
	case invalidMessage
	case noSignature
}

protocol WalletConnection {
	func connect() async throws
	func sign(_ data: Data) async throws -> Data
}

protocol WalletConnectionDelegate {
	mutating func didConnect(connection: WalletConnection)
	mutating func didDisconnect(connection: WalletConnection)
	mutating func failedToConnect(connection: WalletConnection)
}

class WCWalletConnection: WalletConnection, WalletConnectSwift.ClientDelegate {
	var walletConnectClient: WalletConnectSwift.Client!
	var session: WalletConnectSwift.Session?

	init() {
		let peerMeta = Session.ClientMeta(
			name: "xmtp-ios",
			description: "XMTP",
			icons: [],
			url: URL(string: "https://safe.gnosis.io")!
		)
		let dAppInfo = WalletConnectSwift.Session.DAppInfo(peerId: UUID().uuidString, peerMeta: peerMeta)

		walletConnectClient = WalletConnectSwift.Client(delegate: self, dAppInfo: dAppInfo)
	}

	lazy var walletConnectURL: WCURL? = {
		do {
			print("GENERATING WALLET CONNECT URL")
			let keybytes = try Crypto.secureRandomBytes(count: 32)

			return WCURL(
				topic: UUID().uuidString,
				bridgeURL: URL(string: "https://bridge.walletconnect.org")!,
				key: keybytes.toHex
			)
		} catch {
			print("Error getting wallet connect URL: \(error)")
			return nil
		}
	}()

	func connect() async throws {
		guard let url = walletConnectURL else {
			throw WalletConnectionError.walletConnectURL
		}

		try walletConnectClient.connect(to: url)
	}

	func sign(_ data: Data) async throws -> Data {
		guard let session else {
			throw WalletConnectionError.noSession
		}

		guard let walletAddress = walletAddress else {
			throw WalletConnectionError.noAddress
		}

		guard let url = walletConnectURL else {
			throw WalletConnectionError.walletConnectURL
		}

		guard let message = String(data: data, encoding: .utf8) else {
			throw WalletConnectionError.invalidMessage
		}

		return try await withCheckedThrowingContinuation { continuation in
			do {
				try walletConnectClient.personal_sign(url: url, message: message, account: walletAddress) { response in
					if let error = response.error {
						continuation.resume(throwing: error)
						return
					}

					do {
						let resultString = try response.result(as: String.self)

						guard let resultDataBytes = resultString.web3.bytesFromHex else {
							continuation.resume(throwing: WalletConnectionError.noSignature)
							return
						}

						let resultData = Data(resultDataBytes)
						continuation.resume(returning: resultData)
					} catch {
						continuation.resume(throwing: error)
					}
				}
			} catch {
				continuation.resume(throwing: error)
			}
		}
	}

	var walletAddress: String? {
		return session?.walletInfo?.accounts.first
	}

	func client(_: WalletConnectSwift.Client, didConnect _: WalletConnectSwift.WCURL) {}

	func client(_: WalletConnectSwift.Client, didFailToConnect _: WalletConnectSwift.WCURL) {}

	func client(_: WalletConnectSwift.Client, didConnect session: WalletConnectSwift.Session) {
		// TODO: Cache session
		self.session = session
	}

	func client(_: WalletConnectSwift.Client, didUpdate session: WalletConnectSwift.Session) {
		self.session = session
	}

	func client(_: WalletConnectSwift.Client, didDisconnect _: WalletConnectSwift.Session) {
		session = nil
	}
}
