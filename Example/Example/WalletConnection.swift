//
//  WalletConnection.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

import Foundation
import WalletConnectSwift

typealias Wallet = WalletConnectSwift.Client

class WalletConnection: ObservableObject, WalletConnectDelegate {
	@Published var isConnected = false
	@Published var wallet: Wallet?

	var walletConnect: WalletConnect!
	var connectionURL: String!

	init() {
		let walletConnect = WalletConnect(delegate: self)

		self.walletConnect = walletConnect
		connectionURL = walletConnect.connect()
	}

	func failedToConnect() {
		DispatchQueue.main.async {
			self.wallet = self.walletConnect.client
		}
		print("Failed to connect")
	}

	func didConnect() {
		DispatchQueue.main.async {
			self.wallet = self.walletConnect.client
			self.isConnected = true
		}
		print("Did connect")
	}

	func didDisconnect() {
		DispatchQueue.main.async {
			self.wallet = self.walletConnect.client
		}
		print("Did disconnect")
	}

	var deepLinkURL: URL? {
		return URL(string: "wc://wc?uri=\(connectionURL ?? "")")
	}
}
