//
//  WalletConnect.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

import Foundation
import WalletConnectSwift

protocol WalletConnectDelegate {
	func failedToConnect()
	func didConnect()
	func didDisconnect()
}

class WalletConnect {
	var client: WalletConnectSwift.Client!
	var session: Session!
	var delegate: WalletConnectDelegate

	let sessionKey = "sessionKey"

	init(delegate: WalletConnectDelegate) {
		self.delegate = delegate
	}

	func connect() -> String {
		// gnosis wc bridge: https://safe-walletconnect.gnosis.io/
		// test bridge with latest protocol version: https://bridge.walletconnect.org
		let wcUrl = WCURL(topic: UUID().uuidString,
		                  bridgeURL: URL(string: "https://bridge.walletconnect.org")!,
		                  key: try! randomKey())
		let clientMeta = Session.ClientMeta(name: "xmtp-ios example",
		                                    description: "WalletConnectSwift",
		                                    icons: [],
		                                    url: URL(string: "https://safe.gnosis.io")!)
		let dAppInfo = Session.DAppInfo(peerId: UUID().uuidString, peerMeta: clientMeta)
		client = WalletConnectSwift.Client(delegate: self, dAppInfo: dAppInfo)

		print("WalletConnect URL: \(wcUrl.absoluteString)")

		try! client.connect(to: wcUrl)
		return wcUrl.absoluteString
	}

	func reconnectIfNeeded() {
		if let oldSessionObject = UserDefaults.standard.object(forKey: sessionKey) as? Data,
		   let session = try? JSONDecoder().decode(Session.self, from: oldSessionObject)
		{
			client = WalletConnectSwift.Client(delegate: self, dAppInfo: session.dAppInfo)
			try? client.reconnect(to: session)
		}
	}

	// https://developer.apple.com/documentation/security/1399291-secrandomcopybytes
	private func randomKey() throws -> String {
		var bytes = [Int8](repeating: 0, count: 32)
		let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
		if status == errSecSuccess {
			return Data(bytes: bytes, count: 32).toHexString()
		} else {
			// we don't care in the example app
			enum TestError: Error {
				case unknown
			}
			throw TestError.unknown
		}
	}
}

extension WalletConnect: ClientDelegate {
	func client(_: WalletConnectSwift.Client, didFailToConnect _: WCURL) {
		delegate.failedToConnect()
	}

	func client(_: WalletConnectSwift.Client, didConnect _: WCURL) {
		// do nothing
	}

	func client(_: WalletConnectSwift.Client, didConnect session: Session) {
		self.session = session
		let sessionData = try! JSONEncoder().encode(session)
		UserDefaults.standard.set(sessionData, forKey: sessionKey)
		delegate.didConnect()
	}

	func client(_: WalletConnectSwift.Client, didDisconnect _: Session) {
		UserDefaults.standard.removeObject(forKey: sessionKey)
		delegate.didDisconnect()
	}

	func client(_: WalletConnectSwift.Client, didUpdate _: Session) {
		// do nothing
	}
}
