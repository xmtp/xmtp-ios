//
//  Persistence.swift
//  
//
//  Created by Pat Nakajima on 1/20/23.
//

import Foundation
import KeychainAccess
import XMTP

struct Persistence {
	var keychain: Keychain

	init() {
		keychain = Keychain(service: "group.chat.xmtp.example")
	}

	func saveKeys(_ keys: Data) {
		keychain["keys"] = keys
	}

	func loadKeys() -> Data? {
		keychain.getData("keys")
	}

	func save(conversation: Conversation) {
		keychain[key(conversation: conversation)] = conversation
	}

	func key(conversation: Conversation) {
		"conversation-\(conversation.topic)"
	}
}
