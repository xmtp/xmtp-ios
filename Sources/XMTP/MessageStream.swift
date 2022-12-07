//
//  MessageStream.swift
//
//
//  Created by Pat Nakajima on 12/6/22.
//

import Foundation

public struct MessageStream {
	typealias Element = Message

	var client: Client
	var topics: [String]
}
