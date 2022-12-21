//
//  ContentCodec.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

import XMTPProto

enum CodecError: Error {
	case invalidContent
}

public typealias EncodedContent = Xmtp_MessageContents_EncodedContent

public protocol ContentCodec {
	associatedtype T

	var contentType: ContentTypeID { get }
	func encode(content: T) throws -> EncodedContent
	func decode(content: EncodedContent) throws -> T
}
