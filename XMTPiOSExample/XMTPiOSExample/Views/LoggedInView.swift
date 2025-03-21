//
//  LoggedInView.swift
//  XMTPiOSExample
//
//  Created by Pat Nakajima on 11/22/22.
//

import SwiftUI
import XMTPiOS

class EnvironmentCoordinator: ObservableObject {
	@Published var path = NavigationPath()
}

struct LoggedInView: View {
	var client: XMTPiOS.Client

	@StateObject var environmentCoordinator = EnvironmentCoordinator()

	var body: some View {
		NavigationStack(path: $environmentCoordinator.path) {
			VStack {
				ConversationListView(client: client)
				VStack(alignment: .leading) {
					Text("Connected to **\(client.environment.rawValue)** as")
                    Text("`\(client.publicIdentity.identifier)`")
						.bold()
						.textSelection(.enabled)
				}
				.frame(maxWidth: .infinity)
				.font(.caption)
			}
		}
		.environmentObject(environmentCoordinator)
	}
}
