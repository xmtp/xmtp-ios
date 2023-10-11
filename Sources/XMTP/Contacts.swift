//
//  Contacts.swift
//
//
//  Created by Pat Nakajima on 12/8/22.
//

import Foundation

public enum AllowState: String, Codable {
	case allowed, blocked, unknown
}

struct AllowListEntry: Codable, Hashable {
	enum EntryType: String, Codable {
		case address
	}

	static func address(_ address: String, type: AllowState) -> AllowListEntry {
		AllowListEntry(value: address, entryType: .address, permissionType: type)
	}

	var value: String
	var entryType: EntryType
	var permissionType: AllowState
}

struct AllowList {
	var allowedAddresses: Set<AllowListEntry> = []
	var blockedAddresses: Set<AllowListEntry> = []

	var entries: Set<AllowListEntry> = []

	func state(address: String) -> AllowState {
		entries.first(where: { $0.entryType == .address && $0.value == address })?.permissionType ?? AllowState.unknown
	}
}

/// Provides access to contact bundles.
public actor Contacts {
	var client: Client

	// Save all bundles here
	var knownBundles: [String: ContactBundle] = [:]

	// Whether or not we have sent invite/intro to this contact
	var hasIntroduced: [String: Bool] = [:]

	var allowList = AllowList()

	init(client: Client) {
		self.client = client
	}

	public func isAllowed(_ address: String) -> Bool {
		for entry in allowList.entries {
			switch entry.entryType {
			case .address:
				if address == entry.value {
					return entry.permissionType == .allowed
				}
			}
		}

		return false
	}

	public func isBlocked(_ address: String) -> Bool {
		for entry in allowList.entries {
			switch entry.entryType {
			case .address:
				if address == entry.value {
					return entry.permissionType == .blocked
				}
			}
		}

		return false
	}

	public func allow(addresses: [String]) {
		for address in addresses {
			allowList.entries.insert(.address(address, type: .allowed))
		}
	}

	public func block(addresses: [String]) {
		for address in addresses {
			allowList.entries.insert(.address(address, type: .blocked))
		}
	}

	func markIntroduced(_ peerAddress: String, _ isIntroduced: Bool) {
		hasIntroduced[peerAddress] = isIntroduced
	}

	func has(_ peerAddress: String) -> Bool {
		return knownBundles[peerAddress] != nil
	}

	func needsIntroduction(_ peerAddress: String) -> Bool {
		return hasIntroduced[peerAddress] != true
	}

	func find(_ peerAddress: String) async throws -> ContactBundle? {
		if let knownBundle = knownBundles[peerAddress] {
			return knownBundle
		}

		let response = try await client.query(topic: .contact(peerAddress))

		for envelope in response.envelopes {
			// swiftlint:disable no_optional_try
			if let contactBundle = try? ContactBundle.from(envelope: envelope) {
				knownBundles[peerAddress] = contactBundle

				return contactBundle
			}
			// swiftlint:enable no_optional_try
		}

		return nil
	}
}
