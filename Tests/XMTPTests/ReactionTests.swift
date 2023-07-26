//
//  ReactionTests.swift
//  
//
//  Created by Naomi Plasterer on 7/26/23.
//

import Foundation

import XCTest
@testable import XMTP

@available(iOS 15, *)
class ReactionTests: XCTestCase {
    func testCanUseReactionCodec() async throws {
        Client.register(codec: ReactionCodec())
        
        let fixtures = await fixtures()
        let conversation = try await fixtures.aliceClient.conversations.newConversation(with: fixtures.bobClient.address)

        try await conversation.send(text: "hey alice 2 bob")

        let messageToReact = try await conversation.messages()[0]

        let reaction = Reaction(
            reference: messageToReact.id,
            action: .ADDED,
            content: "U+1F603",
            schema: .UNICODE
        )

        try await conversation.send(
            content: reaction,
            options: .init(contentType: ContentTypeReaction)
        )

        let updatedMessages = try await conversation.messages()
        
        let message = try await conversation.messages()[0]
        let content: Reaction = try message.content()
        XCTAssertEqual("U+1F603", content.content)
        XCTAssertEqual(messageToReact.id, content.reference)
        XCTAssertEqual(ReactionAction.ADDED, content.action)
        XCTAssertEqual(ReactionSchema.UNICODE, content.schema)
    }
}
