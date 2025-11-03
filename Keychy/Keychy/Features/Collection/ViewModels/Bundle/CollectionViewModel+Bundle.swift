//
//  CollectionViewModel+Bundle.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/26/25.
//
//MARK: 키링 뭉치함 관련 로직

import SwiftUI
import FirebaseFirestore
import FirebaseStorage

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

extension CollectionViewModel {
    private var db: Firestore {
        Firestore.firestore()
    }
    
    // MARK: - 화면 표시용 배열
    var backgroundViewData: [BackgroundViewData] {
        get { _backgroundViewData }
        set { _backgroundViewData = newValue }
    }
    var carabinerViewData: [CarabinerViewData] {
        get { _carabinerViewData }
        set { _carabinerViewData = newValue }
    }
    
    //MARK: - 새 뭉치 생성 및 파베에 업로드
    func createBundle(
        userId: String,
        name: String,
        selectedBackground: String,
        selectedCarabiner: String,
        keyrings: [String],
        maxKeyrings: Int,
        isMain: Bool,
        completion: @escaping (Bool, String?) -> Void
    ) {
        let newBundle = KeyringBundle(
            userId: userId,
            name: name,
            selectedBackground: selectedBackground,
            selectedCarabiner: selectedCarabiner,
            keyrings: keyrings,
            maxKeyrings: maxKeyrings,
            isMain: isMain,
            createdAt: Date()
        )
        
        let bundleData = newBundle.toDictionary()
        
        let docRef = db.collection("KeyringBundle").document()
        
        docRef.setData(bundleData) { [weak self] error in
            guard self != nil else { return }
            
            if let error = error {
                print("뭉치 생성 에러 : \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            let bundleId = docRef.documentID
            print("뭉치 생성 완료: \(bundleId)")
            completion(true, bundleId)
        }
    }
    
    //MARK: - Firebase에서 사용자의 모든 뭉치 로드
    func fetchAllBundles(uid: String, completion: @escaping (Bool) -> Void) {
        isLoading = true
        
        db.collection("KeyringBundle")
            .whereField("userId", isEqualTo: uid)
            .getDocuments { [weak self] snapshot, error in
                guard let self = self else {
                    completion(false)
                    return
                }
                
                defer { self.isLoading = false }
                
                if let error = error {
                    print("뭉치 로드 에러: \(error.localizedDescription)")
                    completion(false)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("뭉치 문서가 없습니다.")
                    self.bundles = []
                    completion(true)
                    return
                }
                
                let loadedBundles: [KeyringBundle] = documents.compactMap { doc in
                    KeyringBundle(documentId: doc.documentID, data: doc.data())
                }
                
                // 뷰모델 번들에 저장 (정렬은 sortedBundles에서 처리)
                self.bundles = loadedBundles
                completion(true)
            }
    }
    
    // MARK: - 전체 배경 로드 + 소유 여부 주석
    func fetchAllBackgrounds(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            do {
                let snapshot = try await db.collection("Background").getDocuments()
                let items: [Background] = try snapshot.documents.compactMap { try $0.data(as: Background.self) }
                let ownedIds = UserManager.shared.currentUser?.backgrounds ?? []
                let decorated = items.map { bg in
                    BackgroundViewData(background: bg, isOwned: ownedIds.contains(bg.id ?? "")) }
                
                await MainActor.run {
                    self.backgrounds = items
                    self.backgroundViewData = decorated
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                print("배경 로드 에러: \(error.localizedDescription)")
                await MainActor.run {
                    self.backgrounds = []
                    self.backgroundViewData = []
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }
    
    // MARK: - 전체 카라비너 로드 + 소유 여부 주석
    func fetchAllCarabinersAndAnnotate(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            do {
                let snapshot = try await db.collection("Carabiner").getDocuments()
                let items: [Carabiner] = try snapshot.documents.compactMap { try $0.data(as: Carabiner.self) }
                let ownedIds = UserManager.shared.currentUser?.carabiners ?? []
                let decorated = items.map { cb in
                    CarabinerViewData(carabiner: cb, isOwned: ownedIds.contains(cb.id ?? "")) }
                
                await MainActor.run {
                    self.carabiners = items
                    self.carabinerViewData = decorated
                    self.isLoading = false
                    completion(true)
                }
            } catch {
                print("카라비너 로드 에러: \(error.localizedDescription)")
                await MainActor.run {
                    self.carabiners = []
                    self.carabinerViewData = []
                    self.isLoading = false
                    completion(false)
                }
            }
        }
    }
}
