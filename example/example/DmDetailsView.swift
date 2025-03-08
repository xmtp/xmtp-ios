import SwiftUI
import XMTPiOS

// Display the `dm` conversation.
struct DmDetailsView: View {
    let dm: Dm
    var body: some View {
        Text("TODO: DM Details")
            .onAppear {
                Task {
                    try await dm.sync()
                }
            }
    }
}
