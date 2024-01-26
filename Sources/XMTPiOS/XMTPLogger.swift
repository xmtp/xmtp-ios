//
//  Logger.swift
//
//
//  Created by Pat Nakajima on 8/28/23.
//

import Foundation
import LibXMTP
import os

class XMTPLogger: FfiLogger {
	let logger = Logger()

	func log(level: UInt32, levelLabel: String, message: String) {
		logger.info("libxmtp[\(levelLabel)] - \(message)")
	}
}
