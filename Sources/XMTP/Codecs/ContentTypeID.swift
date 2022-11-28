//
//  File.swift
//
//
//  Created by Pat Nakajima on 11/28/22.
//

import XMTPProto

typealias ContentTypeID = Xmtp_MessageContents_ContentTypeId

extension ContentTypeID {
	init(authorityID: String, typeID: String, versionMajor: Int, versionMinor: Int) {
		self.init()
		self.authorityID = authorityID
		self.typeID = typeID
		self.versionMajor = UInt32(versionMajor)
		self.versionMinor = UInt32(versionMinor)
	}
}
