import SwiftUI
import XMTPiOS

// Screen displayed by default when the user has logged in.
//
// This has two tabs:
//  - "Chats" (listing conversations that can be explored)
//  - "Settings" (allowing you to log out etc)
// And it displays the "Add" button for creating new chats.
struct HomeView: View {
    @Environment(\.session) private var session
    @Environment(\.router) private var router
    var body: some View {
        @Bindable var router = router
        TabView {
            Group {
                NavigationStack(path: $router.routes) {
                    ConversationList()
                        // We can do this because `Route` implements `View`
                        // This lets us link to a Route from NavigationLinks elsewhere.
                        .navigationDestination(for: Route.self) { $0 }
                        .toolbar {
                            Button("Add") {
                                router.push(route: .createConversation)
                            }
                        }
                }
                .tabItem {
                    Label("Chats", systemImage: "bubble.left.and.bubble.right")
                }
                SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                    }
            }
        }
    }
}

// List the conversations for the active session.
//
// This refreshes the list when it appears.
// It also supports pull-to-refresh.
private struct ConversationList: View {
    @Environment(\.session) private var session
    var body: some View {
        List(session.conversations) { conversation in
            switch conversation {
            case .group(let group):
                NavigationLink(value: Route.group(group)) {
                    GroupConversationItem(group: group)
                }
            case .dm(let dm):
                NavigationLink(value: Route.dm(dm)) {
                    DmConversationItem(dm: dm)
                }
            }
        }
        .onAppear {
            Task {
                try await session.refreshConversations()
            }
        }
        .refreshable {
            Task {
                try await session.refreshConversations()
            }
        }
    }
}

// Show a group chat item in the conversation list.
private struct GroupConversationItem: View {
    var group: XMTPiOS.Group
    var body: some View {
        // TODO: something prettier
        Text("Group: \((try? group.groupName()) ?? group.id)")
    }
}

// Show a DM item in the conversation list.
private struct DmConversationItem: View {
    var dm: Dm
    var body: some View {
        // TODO: something prettier
        Text("DM: \((try? dm.peerInboxId) ?? dm.id)")
            .lineLimit(1)
    }
}

// Allow the user to logout (and change TBD other settings)
private struct SettingsView: View {
    @Environment(\.session) var session
    var body: some View {
        VStack {
            // TODO: more complete settings view
            Text(session.inboxId ?? "")
            Button("Logout") {
                Task {
                    try await session.clear()
                }
            }
        }.padding()
    }
}
