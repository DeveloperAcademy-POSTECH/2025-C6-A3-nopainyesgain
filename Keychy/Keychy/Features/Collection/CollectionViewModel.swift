//
//  CollectionViewModel.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//

import Foundation

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
}
