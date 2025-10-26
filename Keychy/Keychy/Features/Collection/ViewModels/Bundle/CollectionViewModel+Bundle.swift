//
//  CollectionViewModel+Bundle.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
//MARK: 키링 뭉치함 관련 로직
import Foundation

extension CollectionViewModel {
    
    //임시 함수
    func loadMockData() {
        keyringBundle = Self.createMockData()
    }
    
    static func createMockData() -> [KeyringBundle] {
        return [
            KeyringBundle(
                name: "기본 조합",
                selectedBackground: "starPattern",
                selectedCarabiner: "silver",
                keyrings: ["1", "2", "3"],
                maxKeyrings: 10,
                isMain: true,
                createdAt: Date()
            ),
            KeyringBundle(
                name: "A 조합",
                selectedBackground: "heartPattern",
                selectedCarabiner: "gold",
                keyrings: ["1", "2"],
                maxKeyrings: 5,
                isMain: false,
                createdAt: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
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
    }
}
