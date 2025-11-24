//
//  HomeRoute.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

/// 보관함 탭
enum CollectionRoute: Hashable, BundleRoute {

    // 키링 상세보기
    case collectionKeyringDetailView(Keyring) // 평소
    case collectionKeyringPackageView(Keyring) // 포장된 상태
    
    // 키링 수정하기
    case keyringEditView(Keyring)
    
    // 뭉치함
    case bundleInventoryView
    case bundleDetailView
    case bundleCreateView
    case bundleAddKeyringView
    case bundleNameInputView
    case bundleNameEditView
    case bundleEditView
    
    // 위젯 안내
    case widgetSettingView
    
    // 포장 완료
    case packageCompleteView(keyring: Keyring, postOffice: String)

    case coinCharge
}
