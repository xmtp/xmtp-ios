//
//  WalletConnection.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

import Foundation
import WalletConnectSwift

class WalletConnection: ObservableObject, WalletConnectDelegate {
	@Published var isConnected = false
	@Published var client: WalletConnectSwift.Client?

	var walletConnect: WalletConnect!
	var connectionURL: String!

	init() {
		let walletConnect = WalletConnect(delegate: self)

		self.walletConnect = walletConnect
		connectionURL = walletConnect.connect()
	}

	func failedToConnect() {
		DispatchQueue.main.async {
			self.client = self.walletConnect.client
		}
		print("Failed to connect")
	}

	func didConnect() {
		DispatchQueue.main.async {
			self.client = self.walletConnect.client
		}
		print("Did connect")
	}

	func didDisconnect() {
		DispatchQueue.main.async {
			self.client = self.walletConnect.client
		}
		print("Did disconnect")
	}

	var deepLinkURL: URL? {
		return URL(string: "wc://wc?uri=\(connectionURL ?? "")")
	}
}
