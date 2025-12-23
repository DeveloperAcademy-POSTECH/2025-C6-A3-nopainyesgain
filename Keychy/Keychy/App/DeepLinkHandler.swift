//
//  DeepLinkHandler.swift
//  Keychy
//
//  Created on 12/23/24.
//

import Foundation

class DeepLinkHandler {
    static let shared = DeepLinkHandler()
    private init() {}

    func handle(_ url: URL) {
        // Universal Link 처리
        if url.scheme == "https" && url.host == "keychy-f6011.web.app" {
            handleUniversalLink(url)
            return
        }

        // Custom URL Scheme 처리
        if url.scheme == "keychy" {
            if url.host == "receive" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let postOfficeId = components.queryItems?.first(where: { $0.name == "postOfficeId" })?.value else {
                    return
                }
                DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .receive)
            } else if url.host == "collect" {
                guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                      let postOfficeId = components.queryItems?.first(where: { $0.name == "postOfficeId" })?.value else {
                    return
                }
                DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .collect)
            }
        }
    }

    // Universal Links (배포용)
    private func handleUniversalLink(_ url: URL) {
        guard url.host == "keychy-f6011.web.app" else { return }

        let path = url.path

        // https://keychy-f6011.web.app/receive/POSTOFFICE_ID
        if path.hasPrefix("/receive/") {
            let postOfficeId = String(path.dropFirst("/receive/".count))
            DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .receive)
        }
        // https://keychy-f6011.web.app/collect/POSTOFFICE_ID
        else if path.hasPrefix("/collect/") {
            let postOfficeId = String(path.dropFirst("/collect/".count))
            DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: .collect)
        }
    }
}
