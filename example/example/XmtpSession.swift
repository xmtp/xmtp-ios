import SwiftUI
import SwiftData
import XMTPiOS
import OSLog

// The user's authenticated session with XMTP.
//
// This is how the Views can observe messaging data
// and interact with the XmtpClient.
@Observable
class XmtpSession {
    private static let logger = Logger.forClass(XmtpSession.self)
    enum State {
        case loading
        case loggedOut
        case loggedIn
    }
    
    private(set) var state: State = .loading
    var inboxId: String? {
        client?.inboxID
    }
    private(set) var conversations: [Conversation] = []
    
    private var client: Client?
    private var db: Db
    
    init(db: Db) {
        self.db = db

        // TODO: check for saved credentials from the keychain
        state = .loggedOut
    }
    
    func login() async throws {
        Self.logger.debug("login")
        guard state == .loggedOut else { return }
        state = .loading
        defer {
            Self.logger.info("login \(self.client == nil ? "failed" : "succeeded")")
            state = client == nil ? .loggedOut : .loggedIn
        }
        try await db.erase()
        // TODO: accept as params
        // TODO: use real account
        let account = try PrivateKey.generate()
        let dbKey = Data((0 ..< 32)
            .map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
        
        // To re-use a randomly generated account during dev,
        // copy these from the logs of the first run:
        //        let account = PrivateKey(jsonString: "...")
        //        let dbKey = Data(base64Encoded: "...")
        Self.logger.trace("dbKey: \(dbKey.base64EncodedString())")
        Self.logger.trace("account: \(try! account.jsonString())")
        
        client = try await Client.create(account: account, options: ClientOptions(dbEncryptionKey: dbKey))
        Self.logger.trace("inboxID: \((self.client?.inboxID) ?? "?")")
        
        // TODO: save credentials in the keychain
    }
    
    func refreshConversations() async throws {
        Self.logger.debug("refreshConversations")
        _ = try await client?.conversations.syncAllConversations()
        let conversations = (try? await client?.conversations.list()) ?? []  // TODO: paging etc.
        for conversation in conversations {
            try await conversation.sync()
            _ = try await db.upsertConversation(conversation)
        }
        try await db.save() // TODO: consider doing this elsewhere or allowing autosave to take care of it?
    }
    
    func refreshConversation(conversationId: String) async throws {
        Self.logger.debug("refreshConversation \(conversationId)")
        guard let c = try await client?.conversations.findConversation(conversationId: conversationId) else {
            return // TODO: consider logging failure instead
        }
        _ = try await c.sync()
        _ = try await db.upsertConversation(c)
        let messages = try await c.messages(limit: 10); // TODO: paging etc.
        for message in messages {
            _ = try await db.upsertMessage(message)
        }
        try await db.save()
    }
    
    func sendMessage(_ message: String, to conversationId: String) async throws -> Bool {
        Self.logger.debug("sendMessage \(message) to \(conversationId)")
        guard let c = try await client?.conversations.findConversation(conversationId: conversationId) else {
            return false // TODO: consider logging failure instead
        }
        guard let sentId = try? await c.send(text: message) else {
            return false
        }
        return true
    }
    
    func clear() async throws {
        Self.logger.debug("clear")
        // TODO: clear saved credentials
        client = nil
        try await db.erase()
        state = .loggedOut
    }
}

