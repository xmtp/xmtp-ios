//
//  DecodedMessage.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

import Foundation

public protocol DecodedMessage {
	associatedtype Codec: ContentCodec

	var content: Codec.T { get }
	var senderAddress: String { get }
	var sent: Date { get }
}

extension DecodedMessage {
	var body: String { "" }
}

/// Decrypted messages from a conversation.
public struct TypedDecodedMessage<Codec: ContentCodec>: DecodedMessage {
	public var codec: Codec

	/// The text of a message
	public var content: Codec.T

	/// The wallet address of the sender of the message
	public var senderAddress: String

	/// When the message was sent
	public var sent: Date

	public init(codec: Codec, content: Codec.T, senderAddress: String, sent: Date) {
		self.codec = codec
		self.content = content
		self.senderAddress = senderAddress
		self.sent = sent
	}
}

extension TypedDecodedMessage where Codec == TextCodec {
	init(content: String, senderAddress: String, sent: Date) {
		codec = TextCodec()
		self.content = content
		self.senderAddress = senderAddress
		self.sent = sent
	}
}
