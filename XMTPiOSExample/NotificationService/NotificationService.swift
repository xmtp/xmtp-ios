//
//  NotificationService.swift
//  NotificationService
//
//  Created by Pat Nakajima on 1/20/23.
//

import UserNotifications
import XMTP

class NotificationService: UNNotificationServiceExtension {
	var contentHandler: ((UNNotificationContent) -> Void)?
	var bestAttemptContent: UNMutableNotificationContent?

	override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
		self.contentHandler = contentHandler
		bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

		guard let encryptedMessage = request.content.userInfo["encryptedMessage"] as? String,
					let topic = request.content.userInfo["topic"] as? String,
				  let encryptedMessageData = Data(base64Encoded: Data(encryptedMessage.utf8)) else {
			return
		}

		let envelope = XMTP.Envelope.with { envelope in
			envelope.message = encryptedMessageData
			envelope.contentTopic = topic
		}

		if let bestAttemptContent = bestAttemptContent {
			// Modify the notification content here...
			bestAttemptContent.title = "\(bestAttemptContent.title) [modified]"

			contentHandler(bestAttemptContent)
		}
	}

	override func serviceExtensionTimeWillExpire() {
		// Called just before the extension will be terminated by the system.
		// Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
		if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
			contentHandler(bestAttemptContent)
		}
	}
}
