//
//  LoggedInView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import SwiftUI
import XMTP

struct LoggedInView: View {
	var client: XMTP.Client

	var body: some View {
		NavigationView {
			ConversationListView(client: client)
		}
	}
}
