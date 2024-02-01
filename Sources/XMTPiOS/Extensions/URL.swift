//
//  File.swift
//  
//
//  Created by Pat Nakajima on 2/1/24.
//

import Foundation

extension URL {
	static var documentsDirectory: URL {
		guard let documentsDirectory = try? FileManager.default.url(
			for: .documentDirectory,
			in: .userDomainMask,
			appropriateFor: nil,
			create: false
		) else {
			fatalError("No documents directory")
		}

		return documentsDirectory
	}
}
