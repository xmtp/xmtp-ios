//
//  DecodedMessage.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

import Foundation

/// Decrypted messages from a conversation.
public struct DecodedMessage {
	public var encodedContent: EncodedContent

	/// The wallet address of the sender of the message
	public var senderAddress: String

	/// When the message was sent
	public var sent: Date

	public init(encodedContent: EncodedContent, senderAddress: String, sent: Date) {
		self.encodedContent = encodedContent
		self.senderAddress = senderAddress
		self.sent = sent
	}

	public func content<T>(as _: T.Type) throws -> T {
		if let codec = Client.codecRegistry.find(for: encodedContent.type),
		   let content = try codec.decode(content: encodedContent) as? T
		{
			return content
		}

		throw CodecError.invalidContent
	}

	var fallbackContent: String {
		encodedContent.fallback
	}

	var body: String {
		(try? content(as: String.self)) ?? ""
	}
}
