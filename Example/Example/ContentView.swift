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
	var wallet: WalletConnectSwift.Client
	@State private var client: Client?

	var body: some View {
		Image(systemName: "globe")
			.imageScale(.large)
			.foregroundColor(.accentColor)
		Text("Hello, world!")
		Text(wallet.openSessions()[0].walletInfo?.accounts.debugDescription ?? "No wallet info")
		Button("Connect") {
			Task {
				do {
					let client = try await Client.create(wallet: wallet)
					await MainActor.run {
						self.client = client
					}
					print("Got a client \(client)")
				} catch {
					print("Error creating client: \(error.localizedDescription)")
				}
			}
		}
		.buttonStyle(.borderedProminent)
		.tint(.green)

		if let client {
			Text("Client created just fine.")
		}

		if let r = MemoryKeyStore.shared.privateKeyBundle {
			Text(r.identityKey.publicKey.signature.debugDescription ?? "No signature")
		}
	}
}

struct ContentView: View {
	@State private var isConnected = false
	@StateObject private var walletConnection = WalletConnection()

	var body: some View {
		VStack {
			if let client = walletConnection.client {
				WalletActionsView(wallet: client)
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
