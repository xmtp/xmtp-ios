import SwiftUI
import SwiftData
import XMTPiOS

// Display the conversation.
struct ConversationView: View {
    @Environment(XmtpSession.self) private var session
    let conversationId: String
    @Query var conversation: [Db.Conversation] // .first
    @Query var messages: [Db.Message]
    init(conversationId: String) {
        self.conversationId = conversationId
        _conversation = Query(filter: Db.Conversation.with(conversationId))
    }
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                List(messages) { message in
                    MessageView(conversation: conversation.first!, message: message)
                        .id(message.messageId)
                }
                .onChange(of: messages) { update in
                    proxy.scrollTo(update.last?.messageId ?? "")
                }
            }
            MessageComposerView(conversationId: conversationId)
        }
        .onAppear {
            Task {
                try await session.refreshConversation(conversationId: conversationId)
            }
        }
        .refreshable {
            Task {
                try await session.refreshConversation(conversationId: conversationId)
            }
        }
        .navigationTitle(conversation.first?.name ?? "")
    }
}

struct MessageView: View {
    @Environment(XmtpSession.self) private var session
    let conversation: Db.Conversation
    let message: Db.Message
    @Query var sender: [Db.User] // .first
    init(conversation: Db.Conversation, message: Db.Message) {
        self.conversation = conversation
        self.message = message
        _sender = Query(filter: Db.User.with(message.senderInboxId))
    }
    var body: some View {
        VStack(spacing: 0) {
            Text(message.senderInboxId == session.inboxId ? "Me" : "Someone Else")
            Text(sender.first?.serializedIdentities.joined(separator: ", ") ?? "")
            Text(message.text ?? "(no text)")
            Text(message.sentAt.description)
        }
    }
}

struct MessageComposerView: View {
    @Environment(XmtpSession.self) private var session
    @State private var message: String = ""
    @State private var isSending = false
    @FocusState var isFocused
    let conversationId: String
    var body: some View {
        HStack {
            TextField("Message", text: $message)
                .focused($isFocused)
                .disabled(isSending)
                .padding(4)
                .onSubmit {
                    Task {
                        defer {
                            isSending = false
                        }
                        isSending = true
    //                    try await session.send(message, to: conversationId) // etc
                        if (try await session.sendMessage(message, to: conversationId)) {
                            try await session.refreshConversation(conversationId: conversationId)
                            message = ""
                            isFocused = true
                        }
                    }
                }
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
                .textFieldStyle(.roundedBorder)
                .onAppear {
                    isFocused = true
                }
                .submitLabel(.send)
        }
        .padding(4)
    }
    
    
}
