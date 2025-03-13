import SwiftUI
import SwiftData
import XMTPiOS

// Display the user's profile info.
struct UserView: View {
    @Environment(XmtpSession.self) private var session
    let inboxId: String
    @Query var user: [Db.User]

    init(inboxId: String) {
        self.inboxId = inboxId
        _user = Query(filter: Db.User.with(inboxId))
    }
    
    var body: some View {
        Text("TODO: User Profile \(user.first?.identifiers.first?.serialized ?? "Unknown")")
            .lineLimit(1)
    }
}
