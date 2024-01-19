//
//  File.swift
//  
//
//  Created by Pat Nakajima on 1/16/24.
//

import Foundation
import LibXMTP

// MARK: QueryRequest

extension QueryRequest {
	var toFFI: FfiV2QueryRequest {
		FfiV2QueryRequest(
			contentTopics: contentTopics,
			startTimeNs: startTimeNs,
			endTimeNs: endTimeNs,
			pagingInfo: nil // TODO: fixme
		)
	}
}

extension FfiV2QueryRequest {
	var fromFFI: QueryRequest {
		QueryRequest.with {
			$0.contentTopics = contentTopics
			$0.startTimeNs = startTimeNs
			$0.endTimeNs = endTimeNs
			$0.pagingInfo = PagingInfo() // TODO: fixme
		}
	}
}

// MARK: BatchQueryRequest

extension BatchQueryRequest {
	var toFFI: FfiV2BatchQueryRequest {
		FfiV2BatchQueryRequest(requests: requests.map(\.toFFI))
	}
}

extension FfiV2BatchQueryRequest {
	var fromFFI: BatchQueryRequest {
		BatchQueryRequest.with {
			$0.requests = requests.map(\.fromFFI)
		}
	}
}

// MARK: QueryResponse

extension QueryResponse {
	var toFFI: FfiV2QueryResponse {
		FfiV2QueryResponse(envelopes: envelopes.map(\.toFFI), pagingInfo: nil)
	}
}

extension FfiV2QueryResponse {
	var fromFFI: QueryResponse {
		QueryResponse.with {
			$0.envelopes = envelopes.map(\.fromFFI)
			$0.pagingInfo = PagingInfo() // TODO: fixme
		}
	}
}

// MARK: BatchQueryResponse

extension BatchQueryResponse {
	var toFFI: FfiV2BatchQueryResponse {
		FfiV2BatchQueryResponse(responses: responses.map(\.toFFI))
	}
}

extension FfiV2BatchQueryResponse {
	var fromFFI: BatchQueryResponse {
		BatchQueryResponse.with {
			$0.responses = responses.map(\.fromFFI)
		}
	}
}

// MARK: Envelope

extension Envelope {
	var toFFI: FfiEnvelope {
		FfiEnvelope(contentTopic: contentTopic, timestampNs: timestampNs, message: [UInt8](message))
	}
}

extension FfiEnvelope {
	var fromFFI: Envelope {
		Envelope.with {
			$0.contentTopic = contentTopic
			$0.timestampNs = timestampNs
			$0.message = Data(message)
		}
	}
}

// MARK: PublishRequest

extension PublishRequest {
	var toFFI: FfiPublishRequest {
		FfiPublishRequest(envelopes: envelopes.map(\.toFFI))
	}
}

extension FfiPublishRequest {
	var fromFFI: PublishRequest {
		PublishRequest.with {
			$0.envelopes = envelopes.map(\.fromFFI)
		}
	}
}
