//
//  File.swift
//  
//
//  Created by Alex Risch on 3/28/24.
//

import Foundation

class OpenFramesProxy {
  let inner: ProxyClient

  init(baseUrl: String = OPEN_FRAMES_PROXY_URL) {
      self.inner = ProxyClient(baseUrl: baseUrl);
  }

  func readMetadata(url: String) async throws -> GetMetadataResponse {
      return try await self.inner.readMetadata(url: url);
  }

  func post(url: String, payload: FramePostPayload) async throws -> GetMetadataResponse {
      return try await self.inner.post(url: url, payload: payload);
  }

    func postRedirect(
        url: String,
        payload: FramePostPayload
    ) async throws -> FramesApiRedirectResponse {
      return try await self.inner.postRedirect(url: url, payload: payload);
  }

    func mediaUrl(url: String) async throws -> String {
        if url.hasPrefix("data:") {
            return url
        }
        return self.inner.mediaUrl(url: url);
  }
}
