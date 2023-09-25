//
//  LoginView.swift
//  XMTPChat
//
//  Created by Pat Nakajima on 6/7/23.
//

import SwiftUI
import WebKit
import XMTP
import WalletConnectRelay
import Combine
import SwiftUI
import WalletConnectModal
import Starscream

extension WebSocket: WebSocketConnecting { }
extension Blockchain: @unchecked Sendable { }

struct SocketFactory: WebSocketFactory {
	func create(with url: URL) -> WalletConnectRelay.WebSocketConnecting {
		WebSocket(url: url)
	}
}

struct ModalWrapper: UIViewControllerRepresentable {
	func makeUIViewController(context: Context) -> UIViewController {
		let controller = UIViewController()
		Task {
			try? await Task.sleep(for: .seconds(0.4))
			await MainActor.run {
				WalletConnectModal.present(from: controller)
			}
		}
		return controller
	}

	func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
	}
}

class Signer: SigningKey {
	var account: WalletConnectUtils.Account
	var session: WalletConnectSign.Session

	var address: String {
		account.address
	}

	init(session: WalletConnectSign.Session, account: WalletConnectUtils.Account) {
		self.session = session
		self.account = account
		self.cancellable = Sign.instance.sessionResponsePublisher.sink { response in
			print("RESPONSE: \(response)")

			guard case let .response(codable) = response.result else {
				print("NO RESPONSE")
				return
			}

			let signatureData = Data(hexString: codable.value as! String)
			print("SIGNATURE DATA: \(signatureData)")
			print("GOT A RESPONSE: \(response) signature: \(signatureData)")

			let signature = Signature(bytes: signatureData[0..<64], recovery: Int(signatureData[64]))
			self.continuation?.resume(returning: signature)
			self.continuation = nil
		}
	}

	var cancellable: AnyCancellable?
	var continuation: CheckedContinuation<XMTP.Signature, Never>?

	func sign(_ data: Data) async throws -> XMTP.Signature {
		let address = account.address
		let topic = session.topic
		let blockchain = account.blockchain

		return await withCheckedContinuation { continuation in
			self.continuation = continuation

			Task {
				let method = "personal_sign"
				let walletAddress = address
				let requestParams = AnyCodable([
					String(data: data, encoding: .utf8),
					walletAddress
				])

				let request = Request(
					topic: topic,
					method: method,
					params: requestParams,
					chainId: blockchain
				)

				try await Sign.instance.request(params: request)
			}
		}
	}

	func sign(message: String) async throws -> XMTP.Signature {
		try await sign(Data(message.utf8))
	}
}

struct LoginView: View {
	var onTryDemo: () -> Void
	var onConnecting: () -> Void
	var onConnected: (Client) -> Void
	var publishers: [AnyCancellable] = []

	@State private var isShowingWebview = true

	init(
		onTryDemo: @escaping () -> Void,
		onConnecting: @escaping () -> Void,
		onConnected: @escaping (Client) -> Void
	) {
		self.onTryDemo = onTryDemo
		self.onConnected = onConnected
		self.onConnecting = onConnecting

		Networking.configure(
			projectId: "YOUR PROJECT ID",
			socketFactory: SocketFactory()
		)

		WalletConnectModal.configure(
			projectId: "YOUR PROJECT ID",
			metadata: .init(
				name: "XMTP Chat",
				description: "It's a chat app.",
				url: "https://localhost:4567",
				icons: []
			)
		)

		let requiredNamespaces: [String: ProposalNamespace] = [:]
		let optionalNamespaces: [String: ProposalNamespace] = [
			"eip155": ProposalNamespace(
				chains: [
					Blockchain("eip155:80001")!,        //Polygon Testnet
					Blockchain("eip155:421613")!        //Arbitrum Testnet
				],
				methods: [
					"personal_sign"
				], events: []
			)
		]

		WalletConnectModal.set(sessionParams: .init(
				requiredNamespaces: requiredNamespaces,
				optionalNamespaces: optionalNamespaces,
				sessionProperties: nil
		))

		Sign.instance.sessionSettlePublisher
			.receive(on: DispatchQueue.main)
			.sink { session in
				guard let account = session.accounts.first else { return }

				Task(priority: .high) {
					let signer = Signer(session: session, account: account)
					let client = try await Client.create(
						account: signer,
						options: .init(api: .init(env: .production, isSecure: true))
					)

					await MainActor.run {
						onConnected(client)
					}
				}

				print("GOT AN ACCOUNT \(account)")
			}
			.store(in: &publishers)
	}

	var body: some View {
		ModalWrapper()
	}
}

#Preview {
	LoginView(onTryDemo: {}, onConnecting: {}, onConnected: { _ in })
}
