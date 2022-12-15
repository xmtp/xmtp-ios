//
//  PagingInfo.swift
//
//
//  Created by Pat Nakajima on 12/15/22.
//

import Foundation
import XMTPProto

typealias PagingInfo = Xmtp_MessageApi_V1_PagingInfo
typealias PagingInfoCursor = Xmtp_MessageApi_V1_Cursor
typealias PagingInfoSortDirection = Xmtp_MessageApi_V1_SortDirection

struct Pagination {
	var limit: Int?
	var direction: PagingInfoSortDirection?
	var startTime: Date?
	var endTime: Date?

	var pagingInfo: PagingInfo {
		var info = PagingInfo()

		if let limit {
			info.limit = UInt32(limit)
		}

		if let direction {
			info.direction = direction
		}

		return info
	}
}

extension PagingInfo {
//	/// Note: this is a uint32, while go-waku's pageSize is a uint64
//	public var limit: UInt32 = 0
//
//	public var cursor: Xmtp_MessageApi_V1_Cursor {
//		get {return _cursor ?? Xmtp_MessageApi_V1_Cursor()}
//		set {_cursor = newValue}
//	}
//	/// Returns true if `cursor` has been explicitly set.
//	public var hasCursor: Bool {return self._cursor != nil}
//	/// Clears the value of `cursor`. Subsequent reads from it will return its default value.
//	public mutating func clearCursor() {self._cursor = nil}
//
//	public var direction: Xmtp_MessageApi_V1_SortDirection = .unspecified
	init(limit: Int? = nil, cursor: PagingInfoCursor? = nil, direction: PagingInfoSortDirection? = nil) {
		self.init()

		if let limit {
			self.limit = UInt32(limit)
		}

		if let cursor {
			self.cursor = cursor
		}

		if let direction {
			self.direction = direction
		}
	}
}
