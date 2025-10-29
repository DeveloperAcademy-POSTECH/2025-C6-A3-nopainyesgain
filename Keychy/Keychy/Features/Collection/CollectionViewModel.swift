//
//  CollectionViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import Foundation

@Observable
class CollectionViewModel {
    // 키링 뭉치 관련
    // MARK: - 임시 키링 뭉치
    var bundles: [KeyringBundle] = [
        KeyringBundle(
            name: "기본 조합",
            selectedBackground: "starPattern",
            selectedCarabiner: "silver",
            keyrings: ["1", "2", "3"],
            maxKeyrings: 10,
            isMain: true,
            createdAt: Calendar.current.date(byAdding: .day, value: -5, to: Date()) ?? Date()
        ),
        KeyringBundle(
            name: "A 조합",
            selectedBackground: "heartPattern",
            selectedCarabiner: "gold",
            keyrings: ["1", "2"],
            maxKeyrings: 5,
            isMain: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        ),
        KeyringBundle(
            name: "B 조합",
            selectedBackground: "spadePattern",
            selectedCarabiner: "black",
            keyrings: ["여기에는", "키링의Id가", "들어가겠죠"],
            maxKeyrings: 8,
            isMain: false,
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date()
        )
    ]
    
    var sortedBundles: [KeyringBundle] {
        bundles.sorted { a, b in
            // 메인 뭉치는 항상 첫 번째
            if a.isMain != b.isMain {
                return a.isMain
            }
            return a.createdAt > b.createdAt
        }
    }
    
    // MARK: - 임시 키링 모델 - 실제로는 유저가 보유한 keyring으로 수정 되어야 함
    var keyring: [Keyring] = [
        Keyring(name: "키링 A", bodyImage: "Bundle", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: false, chainLength: 5),
        Keyring(name: "키링 B", bodyImage: "Cherries", soundId: "123", particleId: "123", tags: ["tags", "또치"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: false, chainLength: 5),
        Keyring(name: "키링 C", bodyImage: "InvenPlus", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: true, chainLength: 5),
        Keyring(name: "키링 D", bodyImage: "fireworks", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: true, chainLength: 5),
        Keyring(name: "키링 A", bodyImage: "Widget", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: false, chainLength: 5),
        Keyring(name: "키링 E", bodyImage: "Cherries", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: true, chainLength: 5),
        Keyring(name: "키링 C", bodyImage: "InvenPlus", soundId: "123", particleId: "123", tags: ["tags", "강아지"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: false, chainLength: 5),
        Keyring(name: "키링 D", bodyImage: "fireworks", soundId: "123", particleId: "123", tags: ["tags", "여행"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: true, chainLength: 5),
        Keyring(name: "키링 A", bodyImage: "Bundle", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: false, chainLength: 5),
        Keyring(name: "키링 C", bodyImage: "InvenPlus", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: false, chainLength: 5),
        Keyring(name: "키링 D", bodyImage: "fireworks", soundId: "123", particleId: "123", tags: ["tags"], createdAt: Date(), authorId: "123", copyCount: 1, selectedTemplate: "123", selectedRing: "123", selectedChain: "123", isEditable: true, isPackaged: true, chainLength: 5)
    ]
    
    // MARK: - 배경 모델 (실제로는 Firestore에서 가져온 데이터)
    var backgrounds: [Background] = [
        Background(
            id: "1234",
            backgroundName: "기본 배경 A",
            backgroundImage: "ddochi",
            tags: ["tag1"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date()
        ),
        Background(
            id: "1234",
            backgroundName: "기본 배경 B",
            backgroundImage: "Cherries",
            tags: ["tag1"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date()
        ),
        Background(
            id: "1234",
            backgroundName: "유료 배경 A",
            backgroundImage: "fireworks",
            tags: ["tag1"],
            price: 100,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date()
        ),
        Background(
            id: "1234",
            backgroundName: "유료 배경 B",
            backgroundImage: "ddochi",
            tags: ["tag1"],
            price: 100,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date()
        )
    ]
    var selectedBackground: Background?
    
    // MARK: - 카라비너 모델 (실제로는 Firestore에서 가져온 데이터)
    var carabiners: [Carabiner] = [
        Carabiner(
            id: "1234",
            carabinerName: "카라비너 이름",
            carabinerImage: "ddochi",
            description: "",
            maxKeyringCount: 4,
            tags: ["tags"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Date(),
            keyringXPosition: [0.1, 0.8, 0.2, 0.8],
            keyringYPosition: [0.35, 0.2, 0.8, 0.8]
        ),
        Carabiner(
            id: "1234",
            carabinerName: "카라비너 이름",
            carabinerImage: "ddochi",
            description: "",
            maxKeyringCount: 4,
            tags: ["tags"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
            keyringXPosition: [0.1, 0.8, 0.2, 0.8],
            keyringYPosition: [0.35, 0.2, 0.8, 0.8]
        ),
        Carabiner(
            id: "1234",
            carabinerName: "카라비너 이름",
            carabinerImage: "ddochi",
            description: "",
            maxKeyringCount: 4,
            tags: ["tags"],
            price: 0,
            downloadCount: 0,
            useCount: 0,
            createdAt: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
            keyringXPosition: [0.1, 0.8, 0.2, 0.8],
            keyringYPosition: [0.35, 0.2, 0.8, 0.8]
        )
    ]
    var selectedCarabiner: Carabiner?
}
