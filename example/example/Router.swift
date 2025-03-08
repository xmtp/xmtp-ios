import SwiftUI
import XMTPiOS


// The navigation stack for the logged-in session.
//
// See `HomeView` where this is configured as the NavigationStack(path:)
// so that changes to `.routes` are automatically enacted.
//
// Adding a new route:
//  - add it to the Route enum
//  - implement the Route's == and id methods to they are Identifiable
//  - implement the Route's body method so it's View can be rendered
// Then you can start using the route everywhere.
//  e.g. router.push(.myNewRoute(arg1: val1))
//
@Observable
class Router {
    var routes = [Route]()
    
    func push(route: Route) {
        routes.append(route)
    }
    
    func back() {
        _ = routes.popLast()
    }
}


// Navigable destinations for logged-in sessions.
enum Route: Hashable, Identifiable, View {
    case group(XMTPiOS.Group)
    case dm(Dm)
    case createConversation
    case user(inboxId: String)
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.hashValue)
    }
    
    static func == (lhs: Route, rhs: Route) -> Bool {
        switch (lhs, rhs) {
        case (.group(let lGroup), .group(let rGroup)):
            lGroup.id == rGroup.id
        case (.dm(let l), .dm(let r)):
            l.id == r.id
        case (.createConversation, .createConversation):
            true
        case (.user(let lInboxId), .user(let rInboxId)):
            lInboxId == rInboxId
        default:
            false
        }
    }
    
    var id: String {
        switch self {
        case .group(let group):
            "group:\(group.id)"
        case .dm(let dm):
            "dm:\(dm.id)"
        case .createConversation:
            "create-conversation"
        case .user(let inboxId):
            "user:\(inboxId)"
        }
    }

    // Teach the Route how to render itself.
    //
    // This is what allow us to use this magical line in the HomeView:
    //   .navigationDestination(for: Route.self) { $0 }
    var body: some View {
        switch self {
        case .group(let group):
            GroupDetailsView(group: group)
        case .dm(let dm):
            DmDetailsView(dm: dm)
        case .createConversation:
            CreateConversationView()
        case .user(let inboxId):
            UserView(inboxId: inboxId)
        }
    }
}
