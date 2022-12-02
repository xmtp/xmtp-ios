//
//  ContentView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import SwiftUI
import XMTP

struct ContentView: View {
	enum Status {
		case unknown, connecting, connected(Client), error(String)
	}

	@StateObject var accountManager = AccountManager()

	@State private var status: Status = .unknown

	@State private var isShowingQRCode = false
	@State private var qrCodeImage: UIImage?

	@State private var client: Client?

	var body: some View {
		VStack {
			switch status {
			case .unknown:
				Button("Connect Wallet", action: connectWallet)
			case .connecting:
				ProgressView("Connecting…")
			case let .connected(client):
				LoggedInView(client: client)
			case let .error(error):
				Text("Error: \(error)").foregroundColor(.red)
			}
		}
		.sheet(isPresented: $isShowingQRCode) {
			if let qrCodeImage = qrCodeImage {
				QRCodeSheetView(image: qrCodeImage)
			}
		}
	}

	func connectWallet() {
		status = .connecting

		do {
			switch try accountManager.account.preferredConnectionMethod() {
			case let .qrCode(image):
				qrCodeImage = image

				DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
					self.isShowingQRCode = true
				}
			case let .redirect(url):
				UIApplication.shared.open(url)
			case let .manual(url):
				print("Open \(url) in mobile safari")
			}

			Task {
				do {
					try await accountManager.account.connect()

					for _ in 0 ... 30 {
						if accountManager.account.connection.isConnected {
							let apiOptions = XMTP.ClientOptions.Api(env: .production, isSecure: true)
							let options = XMTP.ClientOptions(api: apiOptions)
							let client = try await Client.create(account: accountManager.account)

							self.status = .connected(client)
							self.isShowingQRCode = false
							return
						}

						try await Task.sleep(for: .seconds(1))
					}

					self.status = .error("Timed out waiting to connect (30 seconds)")
				} catch {
					await MainActor.run {
						self.status = .error("Error connecting: \(error)")
						self.isShowingQRCode = false
					}
				}
			}
		} catch {
			status = .error("No acceptable connection methods found \(error)")
		}
	}
}

struct ContentView_Previews: PreviewProvider {
	static var previews: some View {
		ContentView()
	}
}
