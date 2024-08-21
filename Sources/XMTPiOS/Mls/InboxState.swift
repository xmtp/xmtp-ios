//
//  InboxState.swift
//
//
//  Created by Naomi Plasterer on 8/21/24.
//

import Foundation
import LibXMTP

public struct InboxState {
	var ffiInboxState: FfiInboxState
	
	init(ffiInboxState: FfiInboxState) {
		self.ffiInboxState = ffiInboxState
	}

	public var inboxId: String {
		ffiInboxState.inboxId
	}
	
	public var addresses: [String] {
		ffiInboxState.accountAddresses
	}
	
	public var installationIds: [String] {
		ffiInboxState.installationIds.map { id in id.toHex}
	}
	
	public var recoveryAddress: String {
		ffiInboxState.recoveryAddress
	}

}
