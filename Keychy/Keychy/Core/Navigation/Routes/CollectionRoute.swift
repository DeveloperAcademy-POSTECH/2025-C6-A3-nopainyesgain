//
//  HomeRoute.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

/// 보관함 탭
enum CollectionRoute: Hashable {

    // 키링 상세보기
    case collectionKeyringDetailView(Keyring)
    
    // 키링 수정하기
    case keyringEditView(Keyring)
    
    // 뭉치함
    case bundleInventoryView
    
    // 위젯 안내
    case widgetSettingView
    
    // 포장 완료
    case packageCompleteView
}
