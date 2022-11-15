//
//  ContentView.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

import SwiftUI
import WalletConnectSwift
import XMTPProto

struct WalletActionsView: View {
	var connection: WalletConnection
	var wallet: WalletConnectSwift.Client
	@State private var client: Client?
	@State private var walletAddressFromKey = ""

	var body: some View {
		Image(systemName: "globe")
			.imageScale(.large)
			.foregroundColor(.accentColor)
		Text("Hello, world!")
		Text(wallet.openSessions()[0].walletInfo?.accounts.debugDescription ?? "No wallet info")

		if let client {
			Text("Client created just fine.")

			Text(walletAddressFromKey)
				.bold()

			Button("Get Info") {
				Task {
					let canMessage = await client.canMessage(peerAddress: "0x194c31cAe1418D5256E8c58e0d08Aee1046C6Ed0")
					// TODO: This doesn't work yet.
					print("CAN MESSAGE \(canMessage)")
				}
			}
			.buttonStyle(.borderedProminent)
			.tint(.indigo)
		} else {
			Button("Sign") {
				Task {
					do {
						let client = try await Client.create(wallet: wallet)
						self.walletAddressFromKey = try client.legacyKeys.identityKey.publicKey.walletSignatureAddress()
						await MainActor.run {
							self.client = client
						}
					} catch {
						print("Error creating client: \(error.localizedDescription)")
					}
				}

				if let url = connection.deepLinkURL {
					UIApplication.shared.open(url, options: [:], completionHandler: nil)
				}
			}
			.buttonStyle(.borderedProminent)
			.tint(.green)
		}
	}
}

struct ContentView: View {
	@State private var isConnected = false
	@StateObject private var walletConnection = WalletConnection()

	var body: some View {
		VStack {
			if let client = walletConnection.client {
				WalletActionsView(connection: walletConnection, wallet: client)
			} else {
				Button("Connect") {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						if let url = walletConnection.deepLinkURL, UIApplication.shared.canOpenURL(url) {
							UIApplication.shared.open(url, options: [:], completionHandler: nil)
						} else {
							print("Nope, \(walletConnection.deepLinkURL)")
						}
					}
				}
				.buttonStyle(.borderedProminent)
			}
		}
		.padding()
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
