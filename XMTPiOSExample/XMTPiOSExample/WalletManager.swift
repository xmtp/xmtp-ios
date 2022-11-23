//
//  WalletManager.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import Foundation
import XMTP

class WalletManager: ObservableObject {
	var wallet: XMTP.Wallet

	init() {
		do {
			wallet = try XMTP.Wallet.create()
		} catch {
			fatalError("Wallet could not be created: \(error)")
		}
	}
}
