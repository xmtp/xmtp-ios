import SwiftUI
import SwiftData
import XMTPiOS

// Screen displayed by default when the user has logged in.
//
// This has two tabs:
//  - "Chats" (listing conversations that can be explored)
//  - "Settings" (allowing you to log out etc)
// And it displays the "Add" button for creating new chats.
struct HomeView: View {
    @Environment(XmtpSession.self) private var session
    @Environment(Router.self) private var router
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
    @Environment(XmtpSession.self) private var session
    @Query private var conversations: [Db.Conversation]
    var body: some View {
        List(conversations) { c in
            NavigationLink(value: Route.conversation(conversationId: c.conversationId)) {
                    ConversationItem(conversation: c)
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

// Show an item in the conversation list.
private struct ConversationItem: View {
    var conversation: Db.Conversation
    var body: some View {
        // TODO: something prettier
        Text("\(conversation.name ?? conversation.conversationId)")
    }
}

// Allow the user to logout (and change TBD other settings)
private struct SettingsView: View {
    @Environment(XmtpSession.self) private var session
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
