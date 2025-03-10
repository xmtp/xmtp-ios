//
//  GroupMembershipResult.swift
//
//
//  Created by Naomi Plasterer on 3/10/25.
//

import Foundation
import LibXMTP

public struct GroupMembershipResult {
	var ffiGroupMembershipResult: FfiUpdateGroupMembershipResult

	init(ffiGroupMembershipResult: FfiUpdateGroupMembershipResult) {
		self.ffiGroupMembershipResult = ffiGroupMembershipResult
	}

	public var addedMembers: [InboxId] {
		ffiGroupMembershipResult.addedMembers.map { $0.key }
	}

	public var removedMembers: [InboxId] {
		ffiGroupMembershipResult.removedMembers
	}

	public var failedInstallationIds: [String] {
		ffiGroupMembershipResult.failedInstallations.map { $0.toHex }
	}
}
