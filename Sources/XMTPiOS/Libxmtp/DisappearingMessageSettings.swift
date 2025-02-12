//
//  DisappearingMessageSettings.swift
//  XMTPiOS
//
//  Created by Naomi Plasterer on 2/9/25.
//

import LibXMTP

public struct DisappearingMessageSettings {
	public let disappearStartingAtNs: Int64
	public let retentionDurationInNs: Int64

	static func createFromFfi(_ ffiSettings: FfiMessageDisappearingSettings) -> DisappearingMessageSettings {
		return DisappearingMessageSettings(
			disappearStartingAtNs: ffiSettings.fromNs,
			retentionDurationInNs: ffiSettings.inNs
		)
	}
}
