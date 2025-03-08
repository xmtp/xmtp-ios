import SwiftUI
import XMTPiOS

// The user's authenticated session with XMTP.
//
// This is how the Views can observe messaging data
// and interact with the XmtpClient.
@Observable
class XmtpSession {
    enum State {
        case loading
        case loggedOut
        case loggedIn
    }
    
    private(set) var state: State = .loading
    var address: String? {
        client?.address
    }
    var inboxId: String? {
        client?.inboxID
    }
    private(set) var conversations: [Conversation] = []
    
    private var client: Client?
    
    init() {
        // TODO: check for saved credentials from the keychain
        state = .loggedOut
    }
    
    func login() async throws {
        guard state == .loggedOut else { return }
        state = .loading
        defer {
            state = client == nil ? .loggedOut : .loggedIn
        }
        
        // TODO: accept as params
        // TODO: use real account
        let account = try PrivateKey.generate()
        let dbKey = Data((0 ..< 32)
            .map { _ in UInt8.random(in: UInt8.min ... UInt8.max) })
        
        // To re-use a randomly generated account during dev,
        // copy these from the logs of the first run:
        //        let account = PrivateKey(jsonString: "...")
        //        let dbKey = Data(base64Encoded: "...")
        print("dbKey: \(dbKey.base64EncodedString())")
        print("account: \(try! account.jsonString())")
        
        client = try? await Client.create(account: account, options: ClientOptions(dbEncryptionKey: dbKey))
        print("address: \((client?.address) ?? "?")")
        print("inboxID: \((client?.inboxID) ?? "?")")
        
        // TODO: save credentials in the keychain
    }
    
    func refreshConversations() async throws {
        _ = try await client?.conversations.syncAllConversations()
        conversations = (try? await client?.conversations.list()) ?? []
    }
    
    func clear() async throws {
        // TODO: clear saved credentials
        client = nil
        state = .loggedOut
    }
}
