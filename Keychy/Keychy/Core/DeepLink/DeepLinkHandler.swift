//
//  DeepLinkHandler.swift
//  Keychy
//
//  Created on 12/23/24.
//

import Foundation

/// DeepLink URL을 파싱하여 DeepLinkManager로 전달
///
/// 지원하는 URL 포맷:
/// - Custom URL Scheme: `keychy://receive?postOfficeId=xxx`, `keychy://collect?postOfficeId=xxx`
/// - Universal Link: `https://keychy-f6011.web.app/receive/xxx`, `https://keychy-f6011.web.app/collect/xxx`
class DeepLinkHandler {
    // MARK: - Constants
    private enum Constants {
        static let universalLinkHost = "keychy-f6011.web.app"
        static let customScheme = "keychy"
        static let postOfficeIdKey = "postOfficeId"
    }

    // MARK: - Singleton
    static let shared = DeepLinkHandler()
    private init() {}

    // MARK: - Public Methods
    /// URL을 파싱하여 적절한 딥링크 핸들러로 라우팅
    /// - Parameter url: Custom URL Scheme 또는 Universal Link
    func handle(_ url: URL) {
        // Universal Link 처리
        if url.scheme == "https" && url.host == Constants.universalLinkHost {
            handleUniversalLink(url)
            return
        }

        // Custom URL Scheme 처리
        if url.scheme == Constants.customScheme {
            handleCustomURLScheme(url)
        }
    }

    // MARK: - Private Methods
    /// Universal Link 처리 (https://keychy-f6011.web.app/...)
    private func handleUniversalLink(_ url: URL) {
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

    /// Custom URL Scheme 처리 (keychy://...)
    private func handleCustomURLScheme(_ url: URL) {
        guard let host = url.host,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let postOfficeId = components.queryItems?.first(where: { $0.name == Constants.postOfficeIdKey })?.value else {
            return
        }

        let type: DeepLinkType
        switch host {
        case "receive":
            type = .receive
        case "collect":
            type = .collect
        default:
            return
        }

        DeepLinkManager.shared.handleDeepLink(postOfficeId: postOfficeId, type: type)
    }
}
