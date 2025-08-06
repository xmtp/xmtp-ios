//
//  ArchiveOptions.swift
//  XMTPiOS
//
//  Created by Naomi Plasterer on 8/5/25.
//

import LibXMTP

public struct ArchiveOptions {
	public var startNs: Int64?
	public var endNs: Int64?
	public var archiveElements: [ArchiveElement]

	public init(
		startNs: Int64? = nil,
		endNs: Int64? = nil,
		archiveElements: [ArchiveElement] = [.messages, .consent]
	) {
		self.startNs = startNs
		self.endNs = endNs
		self.archiveElements = archiveElements
	}

	public func toFfi() -> FfiArchiveOptions {
		return FfiArchiveOptions(
			startNs: startNs,
			endNs: endNs,
			elements: archiveElements.map { $0.toFfi() }
		)
	}
}

public enum ArchiveElement {
	case messages
	case consent

	public func toFfi() -> FfiBackupElementSelection {
		switch self {
		case .messages:
			return .messages
		case .consent:
			return .consent
		}
	}

	public static func fromFfi(_ element: FfiBackupElementSelection)
		-> ArchiveElement
	{
		switch element {
		case .messages:
			return .messages
		case .consent:
			return .consent
		}
	}
}

public struct ArchiveMetadata {
	private let ffi: FfiBackupMetadata

	public init(_ ffi: FfiBackupMetadata) {
		self.ffi = ffi
	}

	public var archiveVersion: UInt16 {
		return ffi.backupVersion
	}

	public var elements: [ArchiveElement] {
		return ffi.elements.map { ArchiveElement.fromFfi($0) }
	}

	public var exportedAtNs: Int64 {
		return ffi.exportedAtNs
	}

	public var startNs: Int64? {
		return ffi.startNs
	}

	public var endNs: Int64? {
		return ffi.endNs
	}
}
