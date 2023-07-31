//
//  ReplyCodec.swift
//
//
//  Created by Naomi Plasterer on 7/26/23.
//

import Foundation


public let ContentTypeReply = ContentTypeID(authorityID: "xmtp.org", typeID: "reply", versionMajor: 1, versionMinor: 0)

public struct Reply<T> {
    public var reference: String
    public var content: T
    public var contentType: ContentTypeID
}

public struct ReplyCodec<Content>: ContentCodec {
    public typealias T = Reply<Content>
    public var contentType = ContentTypeReply

    public init() {}

    public func encode(content: Reply<Content>) throws -> EncodedContent {
        var encodedContent = EncodedContent()

        encodedContent.type = ContentTypeReply
        let codec = Client.codecRegistry.find(for: contentType)

        encodedContent.content = try codec.encode(content: content).serializedData()

        return encodedContent
    }

    public func decode(content: EncodedContent) throws -> Reply<Content> {
        let reply = try JSONDecoder().decode(Reply<Content>.self, from: content.content)
        return reply
    }
}
