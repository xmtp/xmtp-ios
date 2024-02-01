//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

import SwiftUI
import XMTPiOS

struct MessageCellView: View {
	var myAddress: String
	var message: DecodedMessage
	@State private var isDebugging = false

	var body: some View {
		VStack {
			HStack {
				if message.senderAddress.lowercased() == myAddress.lowercased() {
					Spacer()
				}
				VStack(alignment: .leading) {
					Text(bodyText)

					if isDebugging {
						Text("My Address \(myAddress)")
							.font(.caption)
						Text("Sender Address \(message.senderAddress)")
							.font(.caption)
					}
				}
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.background(background)
				.cornerRadius(16)
				.foregroundColor(color)
				.onTapGesture {
					withAnimation {
						isDebugging.toggle()
					}
				}
				if message.senderAddress.lowercased() != myAddress.lowercased() {
					Spacer()
				}
			}
		}
	}

	var bodyText: String {
		do {
			return try message.content()
		} catch {
			return message.fallbackContent
		}
		// swiftlint:enable force_try
	}

	var background: Color {
		if message.senderAddress.lowercased() == myAddress.lowercased() {
			return .purple
		} else {
			return .secondary.opacity(0.2)
		}
	}

	var color: Color {
		if message.senderAddress.lowercased() == myAddress.lowercased() {
			return .white
		} else {
			return .primary
		}
	}
}

struct MessageCellView_Previews: PreviewProvider {
	static var previews: some View {
		PreviewClientProvider { client in
			List {
				MessageCellView(myAddress: "0x00", message: DecodedMessage.preview(client: client, topic: "foo", body: "Hi, how is it going?", senderAddress: "0x00", sent: Date()))
			}
			.listStyle(.plain)
		}
	}
}
