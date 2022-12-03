//
//  PreviewClientProvider.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 12/2/22.
//

import SwiftUI
import XMTP

struct PreviewClientProvider<Content: View>: View {
	@State private var client: Client?
	var content: (Client) -> Content

	init(@ViewBuilder _ content: @escaping (Client) -> Content) {
		self.content = content
	}

	var body: some View {
		if let client {
			content(client)
		} else {
			Text("Creating client…")
		}
	}
}

struct PreviewClientProvider_Previews: PreviewProvider {
	static var previews: some View {
		PreviewClientProvider { client in
			Text("Got our client: \(client.address)")
		}
	}
}
