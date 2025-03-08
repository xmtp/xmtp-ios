import SwiftUI
import XMTPiOS

// We "inject" these dependencies via environment values.
extension EnvironmentValues {
    @Entry var session = XmtpSession()  // The current user's session.
    @Entry var router = Router()  // The current navigation path (only used after login).
}

// Initially, the App handles getting the user logged-in.
//
// But after login, the `Router` in the `HomeView` takes over navigation.
@main
struct exampleApp: App {
    @State var session = XmtpSession()
    @State var router = Router()
    var body: some Scene {
        WindowGroup {
            switch session.state {
            case .loading:
                ProgressView()
            case .loggedOut:
                LoginView()
                    .environment(\.session, session)
            case .loggedIn:
                HomeView()
                    .environment(\.session, session)
                    .environment(\.router, router)
            }
        }
    }
}

// Present the login options for the user.
private struct LoginView: View {
    @Environment(\.session) var session
    @State var isLoggingIn = false
    var body: some View {
        // TODO: more login methods
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
