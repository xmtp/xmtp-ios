//
//  String.swift
//
//
//  Created by Naomi Plasterer on 7/1/24.
//

import Foundation


extension String {
	public var hexToData: Data {
		return Data(self.web3.bytesFromHex ?? [])
	}
}

