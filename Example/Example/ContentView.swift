//
//  ContentView.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

import SwiftUI
import WalletConnectSwift
import XMTPProto

struct CanMessageView: View {
	var client: Client
	@State private var address: String = "0x1F935A71f5539fa0eEaa71136Aef39Ab7c64520f"
	@State private var canMessage: Bool?

	var body: some View {
		Form {
			Section("Address") {
				TextEditor(text: $address)
					.lineLimit(2, reservesSpace: true)
			}

			if let canMessage {
				Text(canMessage ? "Yes" : "No")
					.foregroundColor(canMessage ? .green : .red)
					.bold()
			}

			Button("See if can message") {
				Task {
					let canMessage = await client.canMessage(peerAddress: address)
					// TODO: This doesn't work yet.
					await MainActor.run {
						withAnimation {
							self.canMessage = canMessage
						}
					}
					print("CAN MESSAGE \(canMessage)")
				}
			}
			.listRowInsets(.init())
			.listRowBackground(Color.clear)
			.buttonStyle(.borderedProminent)
			.tint(.indigo)
		}
	}
}

struct WalletActionsView: View {
	@Binding var path: NavigationPath
	var connection: WalletConnection
	var wallet: WalletConnectSwift.Client
	@State private var client: Client?
	@State private var walletAddressFromKey = ""

	var body: some View {
		Text(wallet.openSessions()[0].walletInfo?.accounts.debugDescription ?? "No wallet info")

		Button("Sign with Wallet") {
			Task {
				do {
					let client = try await Client.create(wallet: wallet)
					self.walletAddressFromKey = try client.legacyKeys.identityKey.publicKey.walletSignatureAddress()
					await MainActor.run {
						self.client = client
					}

					path.append(NavigationRoute.form(client))
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

enum NavigationRoute: Equatable, Hashable {
	static func == (lhs: NavigationRoute, rhs: NavigationRoute) -> Bool {
		lhs.name == rhs.name
	}

	func hash(into hasher: inout Hasher) {
		hasher.combine(name)
	}

	case sign(Wallet), form(Client)

	var name: String {
		switch self {
		case .sign:
			return "sign"
		case .form:
			return "form"
		}
	}
}

struct ContentView: View {
	@State private var path = NavigationPath()
	@State private var isConnected = false
	@StateObject private var walletConnection = WalletConnection()

	var body: some View {
		NavigationStack(path: $path) {
			VStack {
				Button("Connect to Wallet") {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						if let url = walletConnection.deepLinkURL, UIApplication.shared.canOpenURL(url) {
							UIApplication.shared.open(url, options: [:], completionHandler: nil)
						} else {
							print("Nope, \(walletConnection.deepLinkURL)")
						}
					}
				}
				.buttonStyle(.borderedProminent)
				.navigationDestination(for: NavigationRoute.self) { route in
					switch route {
					case let .sign(wallet):
						WalletActionsView(path: $path, connection: walletConnection, wallet: wallet)
					case let .form(client):
						CanMessageView(client: client)
					}
				}
			}
			.padding()
			.onChange(of: walletConnection.isConnected) { _ in
				print("GOT IS CONNECTED \(walletConnection.isConnected)")
				if let wallet = walletConnection.wallet {
					path.append(NavigationRoute.sign(wallet))
				}
			}
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
