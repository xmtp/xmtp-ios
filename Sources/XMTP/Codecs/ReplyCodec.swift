//
//  ReplyCodec.swift
//
//
//  Created by Naomi Plasterer on 7/26/23.
//

import Foundation


public let ContentTypeReply = ContentTypeID(authorityID: "xmtp.org", typeID: "reply", versionMajor: 1, versionMinor: 0)

public struct Reply: Codable {
    public var reference: String
    public var content: Any
    public var contentType: ContentTypeID
}

public struct ReplyCodec: ContentCodec {
    public var contentType = ContentTypeReply

    public func encode(content: Reply) throws -> EncodedContent {
        var encodedContent = EncodedContent()

        encodedContent.type = ContentTypeReply
        encodedContent.content = try JSONEncoder().encode(content)

        return encodedContent
    }

    public func decode(content: EncodedContent) throws -> Reply {
        let reply = try JSONDecoder().decode(Reply.self, from: content.content)
        return reply
    }
}
