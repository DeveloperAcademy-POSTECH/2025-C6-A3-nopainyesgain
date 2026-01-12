//
//  BundleViewModel.swift
//  Keychy
//
//  Created by 김서현 on 1/9/26.
//

import SwiftUI
import FirebaseFirestore
import FirebaseStorage
import NukeUI

// MARK: - 화면 표시용 구조체
struct BackgroundViewData: Identifiable, Equatable, Hashable {
    var id: String { background.id ?? UUID().uuidString }
    let background: Background
    let isOwned: Bool
}

struct CarabinerViewData: Identifiable, Equatable, Hashable {
    var id: String { carabiner.id ?? UUID().uuidString }
    let carabiner: Carabiner
    let isOwned: Bool
}

/// Firestore에서 가져온 키링 정보를 담는 구조체
struct KeyringInfo {
    let id: String
    let bodyImage: String
    let selectedTemplate: String?
    let soundId: String
    let particleId: String
    let hookOffsetY: CGFloat?
    let chainLength: Int
}

@Observable
class BundleViewModel {
    var db: Firestore {
        Firestore.firestore()
    }
    
    // MARK: - Shared Data
    let dataManager = WorkshopDataManager.shared

    // 배경 및 카라비너 데이터 (WorkshopDataManager에서 가져옴)
    var backgrounds: [Background] { dataManager.backgrounds }
    var selectedBackground: Background?

    var carabiners: [Carabiner] { dataManager.carabiners }
    var selectedCarabiner: Carabiner?
    
    // 뭉치 이름 최대 글자 수
    var maxBundleNameCount: Int = 9
    
    // 뭉치 생성 시 선택 된 키링들을 저장
    var selectedKeyringsForBundle: [Int: Keyring] = [:]
    
    // 뭉치 캡쳐 이미지 (png 데이터)
    var bundleCapturedImage: Data?
    
    // 현재 선택 된 뭉치 - 뭉치 상세뷰 접근 시 데이터 할당 됨
    var selectedBundle: KeyringBundle?
    
    // MARK: - 사용자의 뭉치, 키링 정보를 저장하는 프로퍼티
    var bundles: [KeyringBundle] = []
    var keyring: [Keyring] = []
    
    var isLoading = false
    
    // MARK: - 화면 표시용 배열
    var _backgroundViewData: [BackgroundViewData] = []
    var _carabinerViewData: [CarabinerViewData] = []
    
    var backgroundViewData: [BackgroundViewData] {
        get { _backgroundViewData }
        set { _backgroundViewData = newValue }
    }
    var carabinerViewData: [CarabinerViewData] {
        get { _carabinerViewData }
        set { _carabinerViewData = newValue }
    }
    
    // 정렬된 뭉치 (메인 뭉치 우선 정렬)
    var sortedBundles: [KeyringBundle] {
        bundles.sorted { a, b in
            if a.isMain != b.isMain {
                return a.isMain
            }
            return a.createdAt > b.createdAt
        }
    }
    
    // MARK: - 구성 id 생성 헬퍼 (BundleDetailView의 로직과 동일한 규칙)
    func makeBackgroundId(_ bg: Background?) -> String {
        guard let bg else { return "" }
        return bg.id ?? ""
    }
    
    func makeCarabinerId(_ cb: Carabiner?) -> String {
        guard let cb else { return "" }
        return "\(cb.id ?? "")|\(cb.carabinerX)|\(cb.carabinerY)|\(cb.carabinerWidth)"
    }
    
    func makeKeyringsId(_ list: [MultiKeyringScene.KeyringData]) -> String {
        list
            .sorted(by: { $0.index < $1.index })
            .map { item in
                "\(item.index)|\(item.bodyImageURL)|\((item.templateId ?? ""))|\(item.soundId)|\(item.particleId)|\((item.hookOffsetY ?? 0))|\(item.chainLength)"
            }
            .joined(separator: ";")
    }
    
    // MARK: - 이전 화면에서 전달된 구성 id 저장소
    // 이전 화면에서 pop 직전에 넘겨받은 구성 id를 임시 저장하는 내부 저장소
    var _returnBackgroundId: String?
    var _returnCarabinerId: String?
    var _returnKeyringsId: String?
    
    var returnBackgroundId: String? {
        get { _returnBackgroundId }
        set { _returnBackgroundId = newValue }
    }
    var returnCarabinerId: String? {
        get { _returnCarabinerId }
        set { _returnCarabinerId = newValue }
    }
    var returnKeyringsId: String? {
        get { _returnKeyringsId }
        set { _returnKeyringsId = newValue }
    }
    
    // MARK: - Detail에서 마지막으로 로드한 구성 id (Detail <-> ViewModel 공유)
    // BundleDetailView가 마지막으로 로드 완료한 구성 id를 저장, 다음 진입 때 return~id와 비교해 동일 구성 여부 판단에 사용
    var _lastBackgroundIdForDetail: String?
    var _lastCarabinerIdForDetail: String?
    var _lastKeyringsIdForDetail: String?

    var lastBackgroundIdForDetail: String {
        get { _lastBackgroundIdForDetail ?? "" }
        set { _lastBackgroundIdForDetail = newValue }
    }
    var lastCarabinerIdForDetail: String {
        get { _lastCarabinerIdForDetail ?? "" }
        set { _lastCarabinerIdForDetail = newValue }
    }
    var lastKeyringsIdForDetail: String {
        get { _lastKeyringsIdForDetail ?? "" }
        set { _lastKeyringsIdForDetail = newValue }
    }

    /// 배경, 카라비너의 사용 횟수를 증가시키는 메서드
    func incrementUseCount(
        carabinerId: String?,
        backgroundId: String?
    ) {
        if let carabinerId = carabinerId, !carabinerId.isEmpty {
            db.collection("Carabiner")
                .document(carabinerId)
                .updateData([
                    "useCount": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("[useCount] Carabiner 증가 실패: \(error)")
                    } else {
                        print("[useCount] Carabiner 증가 성공: \(carabinerId)")
                    }
                }
        }
        
        if let backgroundId = backgroundId, !backgroundId.isEmpty {
            db.collection("Background")
                .document(backgroundId)
                .updateData([
                    "useCount": FieldValue.increment(Int64(1))
                ]) { error in
                    if let error = error {
                        print("[useCount] Background 증가 실패: \(error)")
                    } else {
                        print("[useCount] Background 증가 성공: \(backgroundId)")
                    }
                }
        }
    }
    
    /// Resolve Helpers (id -> Model)
    func resolveCarabiner(from id: String) -> Carabiner? {
        carabiners.first { $0.id == id }
    }
    
    func resolveBackground(from id: String) -> Background? {
        backgrounds.first { $0.id == id }
    }
    
    // MARK: - User Background Management
    /// User의 backgrounds 배열에 새 배경 추가
    func addBackgroundToUser(backgroundName: String, userManager: UserManager) async -> Bool {
        guard let userId = userManager.currentUser?.id else {
            print("사용자 ID를 가져올 수 없습니다")
            return false
        }
        
        let db = FirebaseFirestore.Firestore.firestore()
        let userRef = db.collection("User").document(userId)
        
        do {
            // Firebase 업데이트 (ItemPurchaseManager와 동일한 방식)
            try await userRef.updateData([
                "backgrounds": FirebaseFirestore.FieldValue.arrayUnion([backgroundName])
            ])
            
            // UserManager 데이터 갱신
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                userManager.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }
            
            print("User backgrounds 업데이트 완료: \(backgroundName)")
            return true
            
        } catch {
            print("User backgrounds 업데이트 에러: \(error.localizedDescription)")
            return false
        }
    }
    
    ///User의 카라비너에 새 카라비너 추가
    func addCarabinerToUser(carabinerName: String, userManager: UserManager) async -> Bool {
        guard let userId = userManager.currentUser?.id else {
            print("사용자 ID를 가져올 수 없습니다")
            return false
        }
        
        let db = FirebaseFirestore.Firestore.firestore()
        let userRef = db.collection("User").document(userId)
        
        do {
            // Firebase 업데이트 (ItemPurchaseManager와 동일한 방식)
            try await userRef.updateData([
                "carabiners": FirebaseFirestore.FieldValue.arrayUnion([carabinerName])
            ])
            
            // UserManager 데이터 갱신
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                userManager.loadUserInfo(uid: userId) { _ in
                    continuation.resume()
                }
            }
            
            print("User carabiners 업데이트 완료: \(carabinerName)")
            return true
            
        } catch {
            print("User carabiners 업데이트 에러: \(error.localizedDescription)")
            return false
        }
    }
}
