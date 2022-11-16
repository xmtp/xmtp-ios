//
//  ContentView.swift
//  xmtp-ios example
//
//  Created by Pat Nakajima on 11/10/22.
//

public extension Task {
	/// Asynchronously runs the given `operation` in its own task after the specified number of `seconds`.
	///
	/// The operation will be executed after specified number of `seconds` passes. You can cancel the task earlier
	/// for the operation to be skipped.
	///
	/// - Parameters:
	///   - time: Delay time in seconds.
	///   - operation: The operation to execute.
	/// - Returns: Handle to the task which can be cancelled.
	@discardableResult
	static func delayed(
		seconds: TimeInterval,
		operation: @escaping @Sendable () async -> Void
	) -> Self where Success == Void, Failure == Never {
		Self {
			do {
				try await Task<Never, Never>.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
				await operation()
			} catch {}
		}
	}
}

public extension View {
	/// Adds a modifier for this view that fires an action only when a time interval in seconds represented by
	/// `debounceTime` elapses between value changes.
	///
	/// Each time the value changes before `debounceTime` passes, the previous action will be cancelled and the next
	/// action /// will be scheduled to run after that time passes again. This mean that the action will only execute
	/// after changes to the value /// stay unmodified for the specified `debounceTime` in seconds.
	///
	/// - Parameters:
	///   - value: The value to check against when determining whether to run the closure.
	///   - debounceTime: The time in seconds to wait after each value change before running `action` closure.
	///   - action: A closure to run when the value changes.
	/// - Returns: A view that fires an action after debounced time when the specified value changes.
	func onChange<Value>(
		of value: Value,
		debounceTime: TimeInterval,
		perform action: @escaping (_ newValue: Value) -> Void
	) -> some View where Value: Equatable {
		modifier(DebouncedChangeViewModifier(trigger: value, debounceTime: debounceTime, action: action))
	}
}

private struct DebouncedChangeViewModifier<Value>: ViewModifier where Value: Equatable {
	let trigger: Value
	let debounceTime: TimeInterval
	let action: (Value) -> Void

	@State private var debouncedTask: Task<Void, Never>?

	func body(content: Content) -> some View {
		content.onChange(of: trigger) { value in
			debouncedTask?.cancel()
			debouncedTask = Task.delayed(seconds: debounceTime) { @MainActor in
				action(value)
			}
		}
	}
}

import Combine
import CoreImage.CIFilterBuiltins
import SwiftUI
import UIKit
import WalletConnectSwift
import web3
import XMTPProto

struct CanMessageView: View {
	var client: Client
	@State private var address: String = "0x1F935A71f5539fa0eEaa71136Aef39Ab7c64520f"
	@State private var canMessage: Bool?
	@State private var ensName = ""

	var body: some View {
		Form {
			Section("ENS") {
				TextField("ENS", text: $ensName)
					.autocapitalization(.none)
					.onChange(of: ensName, debounceTime: 0.4) { _ in
						print("Checking ens name")
						Task {
							let ethClient = EthereumHttpClient(url: URL(string: "https://mainnet.infura.io/v3/ca05f64fb99645fc926bc1576ac126dc")!)
							let ethNameService = EthereumNameService(client: ethClient)

							do {
								let results = try await ethNameService.resolve(names: [ensName])

								guard let result = results.first else {
									return
								}

								switch result.output {
								case .resolved(let address):
									self.address = address.value
								case .couldNotBeResolved(let error):
									print("Error looking up ENS: \(error)")
								}
							} catch {
								print("error getting name: \(error)")
							}
						}
					}
			}

			Section(header: Text("Address"), footer: Text(ensName)) {
				TextField("Address", text: $address)
					.onChange(of: address, debounceTime: 0.4) { _ in
						Task {
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
									switch result.output {
									case let .couldNotBeResolved(err):
										print("Error resolving \(err)")
									case let .resolved(name):
										self.ensName = name
									}
								}
							} catch {
								print("error getting name: \(error)")
							}
						}
					}
				.autocapitalization(.none)
					.lineLimit(2...)
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
							print("Nope, \(walletConnection.deepLinkURL)")
						}
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
