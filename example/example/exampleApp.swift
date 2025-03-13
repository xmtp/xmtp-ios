import SwiftUI
import SwiftData
import XMTPiOS

// Initially, the App handles getting the user logged-in.
//
// But after login, the `Router` in the `HomeView` takes over navigation.
@main
struct exampleApp: App {
    let dbContainer: ModelContainer
    let db: Db
    let session: XmtpSession
    let router: Router

    init() {
        // Initialize the Database and other dependencies.
        dbContainer =  try! ModelContainer(for: Db.schema)
        db = Db(modelContainer: dbContainer)        
        session = XmtpSession(db: db)
        router = Router()
    }
    var body: some Scene {
        WindowGroup {
            switch session.state {
            case .loading:
                ProgressView()
            case .loggedOut:
                LoginView()
                    .environment(session)
                    .environment(router)
            case .loggedIn:
                HomeView()
                    .environment(session)
                    .environment(router)
            }
        }
        .modelContainer(dbContainer)
    }
}

// Present the login options for the user.
private struct LoginView: View {
    @Environment(XmtpSession.self) var session
    @State var isLoggingIn = false
    var body: some View {
        
        // TODO: support more login methods
        Button("Login (random account)") {
            isLoggingIn = true
            Task {
                defer {
                    isLoggingIn = false
                }
                try await session.login()
            }
        }
        .disabled(isLoggingIn)
    }
}
