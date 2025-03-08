import SwiftUI
import XMTPiOS

// Display the `group` conversation.
struct GroupDetailsView: View {
    let group: XMTPiOS.Group
    var body: some View {
        Text("TODO: Group Details")
            .onAppear {
                Task {
                    try await group.sync()
                }
            }
            .navigationTitle((try? group.groupName()) ?? "")
    }
}
