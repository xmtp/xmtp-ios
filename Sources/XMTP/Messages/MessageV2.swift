//
//  MessageV2.swift
//
//
//  Created by Pat Nakajima on 12/5/22.
//

import Foundation
import XMTPProto

typealias MessageV2 = Xmtp_MessageContents_MessageV2

extension MessageV2 {
	init(headerBytes: Data, ciphertext: CipherText) {
		self.init()
		self.headerBytes = headerBytes
		self.ciphertext = ciphertext
	}
}
