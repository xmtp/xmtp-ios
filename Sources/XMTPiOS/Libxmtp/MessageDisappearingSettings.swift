//
//  MessageDisappearingSettings.swift
//  XMTPiOS
//
//  Created by Naomi Plasterer on 2/9/25.
//

import LibXMTP

public struct MessageDisappearingSettings {
	public let disappearStartingAtNs: Int64
	public let disappearDurationInNs: Int64

	static func createFromFfi(_ ffiSettings: FfiMessageDisappearingSettings) -> MessageDisappearingSettings {
		return MessageDisappearingSettings(
			disappearStartingAtNs: ffiSettings.fromNs,
			disappearDurationInNs: ffiSettings.inNs
		)
	}
}
