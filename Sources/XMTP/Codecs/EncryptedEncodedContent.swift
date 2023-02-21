//
//  EncryptedEncodedContent.swift
//
//
//  Created by Pat on 2/21/23.
//

import Foundation

public struct EncryptedEncodedContent {
	var secret: Data
	var digest: String
	var salt: Data
	var nonce: Data
	var content: Data
}
