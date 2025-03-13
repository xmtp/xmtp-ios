import SwiftData
import XMTPiOS
import Foundation

/// Define the database schema and perform operations against it.
actor Db {
    
    // This schema is defined in the series of @Model classes below.
    static let schema = Schema([
        Db.Conversation.self,
        Db.Message.self,
        Db.User.self
    ])
    
    @Model
    class User {
        @Attribute(.unique) var inboxId: String
        var serializedIdentities: [String]
        var identifiers: [PublicIdentity] {
            get {
                serializedIdentities.map { PublicIdentity.fromSerialized($0) }
            }
        }
        
        // TODO: more user info
        
        init(inboxId: String, identities: [PublicIdentity]) {
            self.inboxId = inboxId
            self.serializedIdentities = identities.map { $0.serialized }
        }
    }
    
    @Model
    class Conversation {
        @Attribute(.unique) var conversationId: String
        var name: String?
        
        // TODO: consider storing dm/group type if we need it

        var memberInboxIds: [String]
        
        // TODO: wrestle with SwiftData to get this working:
        // @Relationship(deleteRule: .cascade, inverse: \DbMessage.conversation) var messages: [DbMessage]

        init(conversationId: String,
             name: String? = nil,
             memberInboxIds: [String] = []
    //         messages: [DbMessage] = []
        ) {
            self.conversationId = conversationId
            self.memberInboxIds = memberInboxIds
    //        self.messages = messages
        }
    }
    
    @Model
    class Message {
        @Attribute(.unique) var messageId: String
        
        var conversationId: String
        // TODO: wrestle with SwiftData to get this working:
        // var conversation: DbConversation
        
        var senderInboxId: String
        // TODO: wrestle with SwiftData to get this working:
        // var sender: Db.User
        
        var sentAt: Date
        var text: String?
        
        init(messageId: String,
             conversationId: String,
             senderInboxId: String,
             sentAt: Date,
             text: String? = nil
        ) {
            self.messageId = messageId
            self.conversationId = conversationId
            self.senderInboxId = senderInboxId
            self.sentAt = sentAt
            self.text = text
        }
    }
    
    /// Here begins the Db actor implementation of the various operations.
    
    nonisolated let executor: any ModelExecutor
    nonisolated let container: ModelContainer

    private var ctx: ModelContext { executor.modelContext }

    init(modelContainer: ModelContainer) {
        self.executor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
        self.container = modelContainer
    }

    func erase() throws {
        try container.erase()
    }

    func save() throws {
        try ctx.save()
    }

    func upsertConversation(_ conversation: XMTPiOS.Conversation) async throws -> Db.Conversation {
        let members = try await conversation.members()
        var memberInboxIds: [String] = []
        for member in members {
            _ = try await upsertUser(member)
            memberInboxIds.append(member.inboxId)
        }
        var name: String? = nil
        if case .group(let g) = conversation {
            name = try g.name()
        }
        let c = Db.Conversation(
            conversationId: conversation.id,
            name: name,
            memberInboxIds: memberInboxIds
        )
        ctx.insert(c)
        return c
    }
    
    func upsertUser(_ member: Member) async throws -> Db.User {
        // TODO: find-then-update for proper upsert behavior

        let u = Db.User(
            inboxId: member.inboxId,
            identities: member.identities
        )
        ctx.insert(u)
        return u
    }
    
    func upsertMessage(_ message: DecodedMessage) async throws -> Db.Message {
        let text = try message.body // TODO: other content types
        let m = Db.Message(
            messageId: message.id,
            conversationId: message.conversationId,
            senderInboxId: message.senderInboxId,
            sentAt: message.sentAt,
            text: text
        )
        ctx.insert(m)
        return m
    }

    func fetchConversation(_ conversationId: String) async throws -> Db.Conversation? {
        let request = FetchDescriptor(predicate: Db.Conversation.with(conversationId))
        return try ctx.fetch(request).first
    }

    func fetchMessage(_ messageId: String) async throws -> Db.Message? {
        let request = FetchDescriptor(predicate: Db.Message.with(messageId: messageId))
        return try ctx.fetch(request).first
    }

    func fetchMessages(_ conversationId: String) async throws -> [Db.Message] {
        let request = FetchDescriptor(predicate: Db.Message.with(conversationId: conversationId))
        return try ctx.fetch(request)
    }

    func fetchUser(_ inboxId: String) async throws -> Db.User? {
        let request = FetchDescriptor(predicate: Db.User.with(inboxId))
        return try ctx.fetch(request).first
    }
}

extension PublicIdentity {
    static func fromSerialized(_ serialized: String) -> PublicIdentity {
        let parts = serialized.split(separator: ":", maxSplits: 1)
        let kind: IdentityKind = switch parts[0] {
        case "ethereum": .ethereum
        case "passkey": .passkey
        default: .passkey
        }
        return PublicIdentity(kind: kind, identifier: String(parts[1]))
    }

    var serialized: String {
        "\(kind):\(identifier)"
    }
}

/// Query Helpers

extension Db.Conversation {
    static func with(_ conversationId: String) -> Predicate<Db.Conversation> {
        #Predicate<Db.Conversation> {
            $0.conversationId == conversationId
        }
    }
}

extension Db.Message {
    static func with(messageId: String) -> Predicate<Db.Message> {
        #Predicate<Db.Message> {
            $0.messageId == messageId
        }
    }
    static func with(conversationId: String) -> Predicate<Db.Message> {
        #Predicate<Db.Message> {
            $0.conversationId == conversationId
        }
    }
}

extension Db.User {
    static func with(_ inboxId: String) -> Predicate<Db.User> {
        #Predicate<Db.User> {
            $0.inboxId == inboxId
        }
    }
}

