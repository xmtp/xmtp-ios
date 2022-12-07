//
//  MessageCellView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/7/22.
//

import SwiftUI
import XMTP

struct MessageCellView: View {
	var myAddress: String
	var message: DecodedMessage

	var body: some View {
		HStack {
			if message.senderAddress == myAddress {
				Spacer()
			}
			Text(message.body)
				.padding(.vertical, 8)
				.padding(.horizontal, 12)
				.background(background)
				.cornerRadius(16)
				.foregroundColor(color)
			if message.senderAddress != myAddress {
				Spacer()
			}
		}
	}

	var background: Color {
		if message.senderAddress == myAddress {
			return .purple
		} else {
			return .secondary.opacity(0.2)
		}
	}

	var color: Color {
		if message.senderAddress == myAddress {
			return .white
		} else {
			return .primary
		}
	}
}

struct MessageCellView_Previews: PreviewProvider {
	static var previews: some View {
		List {
			MessageCellView(myAddress: "0x00", message: DecodedMessage(body: "Hi, how is it going?", senderAddress: "0x00", sent: Date()))
		}
		.listStyle(.plain)
	}
}
