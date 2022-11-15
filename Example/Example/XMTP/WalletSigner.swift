//
//  WalletSigner.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/11/22.
//

import CryptoSwift
import Foundation
import WalletConnectSwift

struct WalletSigner {
	static func identitySigRequestText(keyBytes: [UInt8]) -> String {
		return (
			"XMTP : Create Identity\n" +
				keyBytes.toHexString() +
				"\n" +
				"For more info: https://xmtp.org/signatures/"
		)
	}

	static func sign(wallet: WalletConnectSwift.Client, message: String) async throws -> String {
		guard let session = wallet.openSessions().first, let account = session.walletInfo?.accounts.first else {
			fatalError("No session or wallet info accounts")
		}

		return try await withCheckedThrowingContinuation { continuation in
			do {
				try wallet.personal_sign(
					url: session.url,
					message: message,
					account: account
				) { response in
					print("Got a response \(response)")
					do {
						if let error = response.error {
							continuation.resume(throwing: error as Error)
							return
						}

						let result = try response.result(as: String.self)
						continuation.resume(returning: result)
					} catch {
						continuation.resume(throwing: error)
					}
				}
			} catch {
				print("Error personal signing \(error)")
				continuation.resume(throwing: error)
			}
		}
	}

	struct SignatureParts {
		var r: String = "0x"
		var s: String = "0x"
		var v: UInt8 = 0
		var recoveryParam: UInt8 = 0
	}

	enum WalletSignerError: Error {
		case invalidSignature(String)
	}

	static func signatureParts(from: String) throws -> SignatureParts {
		let bytes = [UInt8](hex: from)

		if bytes.count != 65 {
			print("invalid signature string; must be 65 bytes, was \(bytes.count)")
			throw WalletSignerError.invalidSignature("invalid signature string; must be 65 bytes")
		}

		var result = SignatureParts()
		result.r = [UInt8](bytes[0 ... 32]).toHexString()
		result.s = [UInt8](bytes[33 ... 64]).toHexString()
		result.v = bytes[64]

		if result.v < 27 {
			if result.v == 0 || result.v == 1 {
				result.v += 27
			} else {
				print("invalid signature v byte: \(result)")
				throw WalletSignerError.invalidSignature("invalid signature v byte: \(result.v.description)")
			}
		}

		result.recoveryParam = 1 - (result.v % 2)

		return result
	}
}
