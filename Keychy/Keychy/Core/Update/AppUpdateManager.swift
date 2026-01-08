//
//  AppUpdateManager.swift
//  Keychy
//
//  Created by 길지훈 on 1/8/26.
//

import Foundation

@MainActor
class AppUpdateManager: ObservableObject {
    @Published var showUpdateAlert = false
    @Published var appStoreURL = ""

    // App Store ID (App Store Connect에서 확인)
    private let appStoreID = "6738383686"

    /// 앱 업데이트 체크
    func checkForUpdate() async {
        guard let currentVersion = getCurrentAppVersion() else {
            print("현재 앱 버전을 가져올 수 없습니다.")
            return
        }

        guard let appStoreVersion = await fetchAppStoreVersion() else {
            print("App Store 버전을 가져올 수 없습니다.")
            return
        }

        print("현재 버전: \(currentVersion), App Store 버전: \(appStoreVersion)")

        if isUpdateAvailable(current: currentVersion, appStore: appStoreVersion) {
            appStoreURL = "https://apps.apple.com/app/id\(appStoreID)"
            showUpdateAlert = true
        }
    }

    /// 현재 앱 버전 가져오기
    private func getCurrentAppVersion() -> String? {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// App Store 최신 버전 가져오기
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
            print("iTunes API 호출 실패: \(error.localizedDescription)")
        }

        return nil
    }

    /// 버전 비교 (업데이트 필요 여부)
    private func isUpdateAvailable(current: String, appStore: String) -> Bool {
        let currentComponents = current.split(separator: ".").compactMap { Int($0) }
        let appStoreComponents = appStore.split(separator: ".").compactMap { Int($0) }

        let maxLength = max(currentComponents.count, appStoreComponents.count)

        for i in 0..<maxLength {
            let currentNum = i < currentComponents.count ? currentComponents[i] : 0
            let appStoreNum = i < appStoreComponents.count ? appStoreComponents[i] : 0

            if appStoreNum > currentNum {
                return true  // 업데이트 필요
            } else if appStoreNum < currentNum {
                return false  // 현재 버전이 더 높음
            }
        }

        return false  // 버전 동일
    }
}
