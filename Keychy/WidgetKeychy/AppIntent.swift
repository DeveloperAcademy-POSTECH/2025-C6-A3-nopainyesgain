//
//  AppIntent.swift
//  WidgetKeychy
//
//  위젯 설정용 AppIntent
//  - 위젯 편집 시 키링 선택 UI 제공
//  - App Group에서 사용 가능한 키링 목록 조회
//

import WidgetKit
import AppIntents

// MARK: - Keyring Entity

/// 위젯에서 선택 가능한 키링 엔티티
struct KeyringEntity: AppEntity {
    let id: String      // Firestore documentId
    let name: String    // 키링 이름

    /// 타입 표시명 (위젯 설정 UI에 "키링" 표시)
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "키링"

    /// 개별 키링 표시 방식 (키링 이름 표시)
    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    /// 키링 목록 조회용 쿼리
    static var defaultQuery = KeyringEntityQuery()
}

// MARK: - Keyring Entity Query

/// 위젯에서 선택 가능한 키링 목록을 App Group에서 조회
struct KeyringEntityQuery: EntityQuery {
    /// 특정 ID로 키링 찾기 (위젯이 이미 설정된 키링을 복원할 때 사용)
    func entities(for identifiers: [String]) async throws -> [KeyringEntity] {
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        return availableKeyrings
            .filter { identifiers.contains($0.id) }
            .map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    /// 위젯 설정 UI에 표시할 키링 목록 (사용자가 선택 가능한 전체 목록)
    func suggestedEntities() async throws -> [KeyringEntity] {
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        return availableKeyrings.map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    /// 기본 선택 키링 (목록의 첫 번째 키링)
    func defaultResult() async -> KeyringEntity? {
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        guard let first = availableKeyrings.first else { return nil }
        return KeyringEntity(id: first.id, name: first.name)
    }
}

// MARK: - Configuration Intent

/// 위젯 설정 인텐트 (위젯 편집 시 표시되는 설정 화면)
struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "키링 선택" }
    static var description: IntentDescription { "위젯에 표시할 키링을 선택하세요" }

    /// 사용자가 선택한 키링 (nil이면 플레이스홀더 표시)
    @Parameter(title: "키링")
    var selectedKeyring: KeyringEntity?
}
