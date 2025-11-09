//
//  AppIntent.swift
//  WidgetKeychy
//
//  Created by rundo on 11/9/25.
//

import WidgetKit
import AppIntents

// MARK: - Keyring Entity

struct KeyringEntity: AppEntity {
    let id: String
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "키링"

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = KeyringEntityQuery()
}

// MARK: - Keyring Entity Query

struct KeyringEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [KeyringEntity] {
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        return availableKeyrings
            .filter { identifiers.contains($0.id) }
            .map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    func suggestedEntities() async throws -> [KeyringEntity] {
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        return availableKeyrings.map { KeyringEntity(id: $0.id, name: $0.name) }
    }

    func defaultResult() async -> KeyringEntity? {
        let availableKeyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        guard let first = availableKeyrings.first else { return nil }
        return KeyringEntity(id: first.id, name: first.name)
    }
}

// MARK: - Configuration Intent

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource { "키링 선택" }
    static var description: IntentDescription { "위젯에 표시할 키링을 선택하세요" }

    @Parameter(title: "키링")
    var selectedKeyring: KeyringEntity?
}
