//
//  ReviewManager.swift
//  Keychy
//
//  Created by 길지훈 on 1/15/26.
//

import Foundation
import StoreKit
import UIKit

// MARK: - Review Trigger

enum ReviewTrigger: String {
    case keyring5 = "keyring5"              // 키링 5개 이상 완성
    case active7days = "active7days"        // 7일 중 3일 방문 + 키링 2개
    case template3 = "template3"            // 서로 다른 템플릿 3종
    case firstBundle = "firstBundle"        // 첫 뭉치 생성
}

// MARK: - Review Manager

/// 앱 리뷰 요청 관리자
/// 다양한 시점에 자연스럽게 리뷰를 요청하되, 사용자 경험을 해치지 않도록 보수적으로 관리
class ReviewManager {
    static let shared = ReviewManager()

    private init() {}

    /// 최소 요청 간격 (60일)
    private let minimumInterval: TimeInterval = 60 * 24 * 60 * 60

    private let lastRequestDateKey = "lastReviewRequestDate"
    private let triggeredConditionsKey = "triggeredReviewConditions"

    /// 마지막 요청 날짜
    private var lastRequestDate: Date? {
        get { UserDefaults.standard.object(forKey: lastRequestDateKey) as? Date }
        set { UserDefaults.standard.set(newValue, forKey: lastRequestDateKey) }
    }

    /// 이미 트리거된 조건들
    private var triggeredConditions: Set<String> {
        get {
            let array = UserDefaults.standard.array(forKey: triggeredConditionsKey) as? [String] ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: triggeredConditionsKey)
        }
    }

    /// 조건 체크 & 리뷰 요청
    func requestReview(for trigger: ReviewTrigger) {
        #if DEBUG
        // 디버그 빌드에서는 리뷰 요청 안 함
        #else
        guard !isAlreadyTriggered(trigger) else { return }
        guard !isRequestedToday() else { return }
        guard isMinimumIntervalPassed() else { return }

        performReviewRequest(for: trigger)
        #endif
    }

    // MARK: - Tracking

    /// 키링 5개 완성 체크
    func checkKeyring5(totalKeyringCount: Int) {
        guard totalKeyringCount >= 5 else { return }
        requestReview(for: .keyring5)
    }

    /// 첫 뭉치 생성 체크
    func checkFirstBundle(isFirstBundle: Bool) {
        guard isFirstBundle else { return }
        requestReview(for: .firstBundle)
    }

    /// 템플릿 3종 체크
    func trackTemplateUsage(templateId: String) {
        var templates = usedTemplates
        templates.insert(templateId)
        usedTemplates = templates

        if templates.count >= 3 {
            requestReview(for: .template3)
        }
    }

    /// 7일 중 3일 방문 + 키링 2개 체크
    func checkActive7Days(totalKeyringCount: Int) {
        trackDailyVisit()

        let visitDays = uniqueVisitDaysInLast7Days()
        guard visitDays >= 3 && totalKeyringCount >= 2 else { return }

        requestReview(for: .active7days)
    }

    private var usedTemplates: Set<String> {
        get {
            let array = UserDefaults.standard.array(forKey: "usedTemplatesForReview") as? [String] ?? []
            return Set(array)
        }
        set {
            UserDefaults.standard.set(Array(newValue), forKey: "usedTemplatesForReview")
        }
    }

    private func trackDailyVisit() {
        let today = Calendar.current.startOfDay(for: Date())
        var visits = visitDates
        visits.insert(today)
        visitDates = visits
    }

    private var visitDates: Set<Date> {
        get {
            let array = UserDefaults.standard.array(forKey: "visitDatesForReview") as? [TimeInterval] ?? []
            return Set(array.map { Date(timeIntervalSince1970: $0) })
        }
        set {
            let intervals = newValue.map { $0.timeIntervalSince1970 }
            UserDefaults.standard.set(intervals, forKey: "visitDatesForReview")
        }
    }

    private func uniqueVisitDaysInLast7Days() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -6, to: today)!

        let recentVisits = visitDates.filter { $0 >= sevenDaysAgo }
        return recentVisits.count
    }

    private func isAlreadyTriggered(_ trigger: ReviewTrigger) -> Bool {
        return triggeredConditions.contains(trigger.rawValue)
    }

    private func isRequestedToday() -> Bool {
        guard let lastDate = lastRequestDate else { return false }
        return Calendar.current.isDateInToday(lastDate)
    }

    private func isMinimumIntervalPassed() -> Bool {
        guard let lastDate = lastRequestDate else { return true }
        let interval = Date().timeIntervalSince(lastDate)
        return interval >= minimumInterval
    }

    private func performReviewRequest(for trigger: ReviewTrigger) {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else { return }

        // 시스템 리뷰 요청
        AppStore.requestReview(in: scene)

        // 기록 저장
        lastRequestDate = Date()
        var conditions = triggeredConditions
        conditions.insert(trigger.rawValue)
        triggeredConditions = conditions
    }
}
