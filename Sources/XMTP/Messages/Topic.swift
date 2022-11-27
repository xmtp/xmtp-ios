//
//  Topic.swift
//
//
//  Created by Pat Nakajima on 11/17/22.
//

import XMTPProto

enum Topic: CustomStringConvertible {
	case userPrivateStoreKeyBundle(String),
	     contact(String),
			 userIntro(String),
			 userInvite(String),
			 directMessageV2(String)

	var description: String {
		switch self {
		case let .userPrivateStoreKeyBundle(address):
			return wrap("privatestore-\(address)")
		case let .contact(address):
			return wrap("contact-\(address)")
		case let .userIntro(address):
			return wrap("intro-\(address)")
		case let .userInvite(address):
			return wrap("invite-\(address)")
		case let .directMessageV2(randomString):
			return wrap("m-\(randomString)")
		}
	}

	private func wrap(_ value: String) -> String {
		"/xmtp/0/\(value)/proto"
	}
}
