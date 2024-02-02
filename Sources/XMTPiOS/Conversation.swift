//
//  Conversation.swift
//
//
//  Created by Pat Nakajima on 2/1/24.
//

import Foundation

public enum Conversation: Identifiable, Hashable, Equatable {
	case directMessage(DirectMessage), group(Group)

	public var id: Data {
		switch self {
		case .directMessage(let dm):
			return Data(dm.topic.utf8)
		case .group(let group):
			return group.id
		}
	}

	public var createdAt: Date {
		switch self {
		case .directMessage(let directMessage):
			return directMessage.createdAt
		case .group(let group):
			return group.createdAt
		}
	}
}
