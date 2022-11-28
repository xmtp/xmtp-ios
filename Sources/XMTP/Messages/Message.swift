//
//  Message.swift
//
//
//  Created by Pat Nakajima on 11/27/22.
//

import XMTPProto

typealias Message = Xmtp_MessageContents_Message

extension Message {
	init(v1: MessageV1) {
		self.init()
		self.v1 = v1
	}
}
