//
//  ContentView.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import WalletConnectSwift
import web3
import XMTPProto

enum CanMessageStatus {
	case unknown, loading, yes, no
}

struct CanMessageView: View {
	var client: Client
	@State private var address: String = "0x66942eC8b0A6d0cff51AEA9C7fd00494556E705F"
	@State private var status: CanMessageStatus = .unknown
	@State private var ensName = ""

	var body: some View {
		Form {
			Section("ENS") {
				TextField("ENS", text: $ensName) { _ in
					withAnimation {
						self.status = .loading
					}
					Task(priority: .userInitiated) {
						let ethClient = EthereumHttpClient(url: URL(string: "https://mainnet.infura.io/v3/ca05f64fb99645fc926bc1576ac126dc")!)
						let ethNameService = EthereumNameService(client: ethClient)

						do {
							let results = try await ethNameService.resolve(names: [ensName])

							guard let result = results.first else {
								return
							}

							switch result.output {
							case let .resolved(address):
								await MainActor.run {
									withAnimation {
										self.address = address.toChecksumAddress()
										self.status = .unknown
									}
								}
							case let .couldNotBeResolved(error):
								print("Error looking up ENS: \(error)")
								withAnimation {
									self.status = .unknown
								}
							}
						} catch {
							await MainActor.run {
								withAnimation {
									self.status = .unknown
								}
							}
							print("error getting name: \(error)")
						}
					}
				}
				.autocapitalization(.none)
				.autocorrectionDisabled(true)
			}

			Section(header: Text("Address")) {
				TextField("Address", text: $address) { _ in
					status = .loading
					Task(priority: .userInitiated) {
						let ethClient = EthereumHttpClient(url: URL(string: "https://mainnet.infura.io/v3/ca05f64fb99645fc926bc1576ac126dc")!)
						let ethNameService = EthereumNameService(client: ethClient)

						do {
							let results = try await ethNameService.resolve(addresses: [
								EthereumAddress(address),
							])

							guard let result = results.first else {
								return
							}

							await MainActor.run {
								status = .unknown
								switch result.output {
								case let .couldNotBeResolved(err):
									print("Error resolving \(err)")
								case let .resolved(name):
									self.ensName = name
								}
							}
						} catch {
							await MainActor.run {
								status = .unknown
							}
						}
					}
				}
				.autocorrectionDisabled(true)
				.autocapitalization(.none)
				.lineLimit(2...)

				switch status {
				case .loading:
					Text("Loading…")
						.foregroundColor(.secondary)
				case .yes:
					Text("Can message this address")
						.foregroundColor(.green)
						.bold()
				case .no:
					Text("Cannot message this address")
						.bold()
				default:
					EmptyView()
				}
			}

			Button("See if can message") {
				status = .loading
				Task {
					let canMessage = await client.canMessage(peerAddress: address)
					// TODO: This doesn't work yet.
					await MainActor.run {
						withAnimation {
							self.status = canMessage ? .yes : .no
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

	func lookupAddress() {}

	func lookupName() {}
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

struct CodeView: View {
	var code: String
	@State private var image: UIImage?

	var body: some View {
		if let image {
			Image(uiImage: image)
		} else {
			ProgressView()
				.onAppear {
					setImage()
				}
		}
	}

	func setImage() {
		let data = Data(code.utf8)
		let context = CIContext()
		let filter = CIFilter.qrCodeGenerator()
		filter.setValue(data, forKey: "inputMessage")

		let outputImage = filter.outputImage!
		let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 3, y: 3))
		let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent)!

		image = UIImage(cgImage: cgImage)
	}
}

struct ContentView: View {
	@State private var path = NavigationPath()
	@State private var isConnected = false
	@State private var isShowingQR = false
	@StateObject private var walletConnection = WalletConnection()

	var body: some View {
		NavigationStack(path: $path) {
			VStack {
				Button("Connect to Wallet") {
					DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
						if let url = walletConnection.deepLinkURL, UIApplication.shared.canOpenURL(url) {
							UIApplication.shared.open(url, options: [:], completionHandler: nil)
						} else {
							self.isShowingQR = true
						}
					}
				}
				.onChange(of: walletConnection.isConnected) { _ in
					if walletConnection.isConnected {
						self.isShowingQR = false
					}
				}
				.sheet(isPresented: $isShowingQR) {
					CodeView(code: walletConnection.deepLinkURL?.absoluteString ?? "")
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
