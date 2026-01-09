//
//  AppUpdateManager.swift
//  Keychy
//
//  Created by 길지훈 on 1/8/26.
//

import Foundation
import SwiftUI

/// 앱 업데이트 관리
/// iTunes Search API를 통해 App Store의 최신 버전을 확인하고, 업데이트가 필요한 경우 Alert를 표시
@Observable
@MainActor
class AppUpdateManager {
    var showUpdateAlert = false
    var appStoreURL = ""

    private let appStoreID = "6738383686"

    /// 앱 업데이트 체크
    func checkForUpdate() async {
        #if DEBUG
        // 디버그 빌드에서는 업데이트 체크 안 함
        return
        #endif

        guard let currentVersion = getCurrentAppVersion(),
              let appStoreVersion = await fetchAppStoreVersion() else {
            return
        }

        // 업데이트가 필요한 경우 Alert 표시
        if isUpdateAvailable(current: currentVersion, appStore: appStoreVersion) {
            appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"

            withAnimation {
                showUpdateAlert = true
            }
        }
    }

    /// Info.plist에서 현재 앱 버전 가져오기
    private func getCurrentAppVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// iTunes Search API를 통해 App Store의 최신 버전 가져오기
    private func fetchAppStoreVersion() async -> String? {
        guard let bundleID = Bundle.main.bundleIdentifier,
              let url = URL(string: "https://itunes.apple.com/lookup?bundleId=\(bundleID)") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)

            if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let results = json["results"] as? [[String: Any]],
               let appStoreVersion = results.first?["version"] as? String {
                return appStoreVersion
            }
        } catch {
            return nil
        }

        return nil
    }

    /// 버전 비교하여 업데이트 필요 여부 확인
    /// - Parameters:
    ///   - current: 현재 앱 버전 (예: "1.0.0")
    ///   - appStore: App Store 버전 (예: "1.1.0")
    /// - Returns: App Store 버전이 더 높으면 true
    private func isUpdateAvailable(current: String, appStore: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let appStoreComponents = appStore.split(separator: ".").compactMap { Int($0) }
        let maxLength = max(currentComponents.count, appStoreComponents.count)

        for i in 0..<maxLength {
            let currentNum = i < currentComponents.count ? currentComponents[i] : 0
            let appStoreNum = i < appStoreComponents.count ? appStoreComponents[i] : 0

            if appStoreNum > currentNum {
                return true
            } else if appStoreNum < currentNum {
                return false
            }
        }

        return false
    }
}
