//
//  EncryptedEncodedContent.swift
//
//
//  Created by Pat on 2/21/23.
//

import Foundation

public struct EncryptedEncodedContent {
	public var secret: Data
	public var digest: String
	public var salt: Data
	public var nonce: Data
	public var payload: Data
}
