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
    var keyringBundle: [KeyringBundle] = []
    
    init() {
        loadMockData()
    }
}
