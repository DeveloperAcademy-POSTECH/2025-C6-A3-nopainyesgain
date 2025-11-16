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
        
        // Firestore가 자동 생성한 문서 ID 사용
        let docRef = db.collection("KeyringBundle").document()
        
        docRef.setData(bundleData) { [weak self] error in
            guard let self = self else { return }
            
            if let error = error {
                print("뭉치 생성 에러 : \(error.localizedDescription)")
                completion(false, nil)
                return
            }
            
            let bundleId = docRef.documentID
            
            // 로컬 번들 목록에 추가 (documentId 포함)
            DispatchQueue.main.async {
                var updatedBundle = newBundle
                updatedBundle.documentId = bundleId
                self.bundles.append(updatedBundle)
                
                print("뭉치 생성 완료: \(bundleId)")
                // 배열 업데이트 후 completion 호출
                completion(true, bundleId)
            }
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
    
    // MARK: - 전체 배경 로드 + 소유 여부 주석 (dataManager 활용)
    func fetchAllBackgrounds(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            // dataManager를 통해 캐싱된 데이터 활용
            await dataManager.fetchBackgroundsIfNeeded()
            
            // dataManager에서 이미 로드된 데이터 가져오기
            let items = backgrounds // dataManager.backgrounds
            let ownedIds = UserManager.shared.currentUser?.backgrounds ?? []
            let decorated = items.map { bg in
                BackgroundViewData(background: bg, isOwned: ownedIds.contains(bg.id ?? ""))
            }
            
            await MainActor.run {
                self.backgroundViewData = decorated
                self.isLoading = false
                completion(true)
            }
        }
    }
    
    // MARK: - 전체 카라비너 로드 + 소유 여부 주석 (dataManager 활용)
    func fetchAllCarabiners(completion: @escaping (Bool) -> Void) {
        isLoading = true
        Task {
            // dataManager를 통해 캐싱된 데이터 활용
            await dataManager.fetchCarabinersIfNeeded()
            
            // dataManager에서 이미 로드된 데이터 가져오기
            let items = carabiners // dataManager.carabiners
            let ownedIds = UserManager.shared.currentUser?.carabiners ?? []
            let decorated = items.map { cb in
                CarabinerViewData(carabiner: cb, isOwned: ownedIds.contains(cb.id ?? ""))
            }
            
            await MainActor.run {
                self.carabinerViewData = decorated
                self.isLoading = false
                completion(true)
            }
        }
        // 카라비너는 기본 카라비너 자동 선택 됨
        selectedCarabiner = carabiners.first
    }
    
    /// Resolve Helpers (id -> Model)
    func resolveCarabiner(from id: String) -> Carabiner? {
        carabiners.first { $0.id == id }
    }
    
    func resolveBackground(from id: String) -> Background? {
        backgrounds.first { $0.id == id }
    }
    
    /// Firestore 문서 id -> Keyring 모델 해석
    func resolveKeyring(from documentId: String) -> Keyring? {
        let result = keyring.first { kr in
            keyringDocumentIdByLocalId[kr.id] == documentId
        }
        return result
    }
    
    func createKeyringDataList(carabiner: Carabiner, geometry: CGSize) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []

        guard let bundle = selectedBundle else {
            return dataList
        }

        // bundle.keyrings 배열을 순회 (각 인덱스는 카라비너 위치)
        for index in 0..<carabiner.maxKeyringCount {
            // 번들에 저장된 문서 id (없으면 "none")
            let docId = bundle.keyrings[index] ?? "none"

            if docId == "none" || docId.isEmpty {
                continue
            }

            guard let keyring = resolveKeyring(from: docId) else {
                continue
            }
            
            let soundId = keyring.soundId
            
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()
            
            let relativePosition = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )
            
            let data = MultiKeyringScene.KeyringData(
                index: index, // 카라비너 위치 인덱스
                position: relativePosition,
                bodyImageURL: keyring.bodyImage,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: keyring.particleId
            )
            dataList.append(data)
        }
        
        return dataList
    }
    
    //MARK: - 메인 번들 업데이트 (기존 메인 해제 포함)
    func updateBundleMainStatus(bundle: KeyringBundle, isMain: Bool, completion: @escaping (Bool) -> Void) {
        guard let documentId = bundle.documentId else {
            completion(false)
            return
        }
        
        // 새로운 번들을 메인으로 설정하는 경우, 기존 메인 번들을 먼저 해제
        if isMain {
            // 현재 메인인 다른 번들들을 찾아서 해제
            let currentMainBundles = bundles.filter { $0.isMain && $0.documentId != bundle.documentId }
            
            let dispatchGroup = DispatchGroup()
            var hasError = false
            
            // 기존 메인 번들들을 모두 해제
            for mainBundle in currentMainBundles {
                guard let mainDocId = mainBundle.documentId else { continue }
                
                dispatchGroup.enter()
                db.collection("KeyringBundle").document(mainDocId).updateData([
                    "isMain": false
                ]) { error in
                    if let error = error {
                        hasError = true
                    }
                    dispatchGroup.leave()
                }
            }
            
            // 모든 기존 메인 번들 해제 완료 후, 새로운 메인 번들 설정
            dispatchGroup.notify(queue: .main) {
                if hasError {
                    completion(false)
                    return
                }
                
                // 새로운 번들을 메인으로 설정
                self.db.collection("KeyringBundle").document(documentId).updateData([
                    "isMain": isMain
                ]) { [weak self] error in
                    self?.handleMainBundleUpdateCompletion(
                        error: error,
                        bundle: bundle,
                        isMain: isMain,
                        currentMainBundles: currentMainBundles,
                        completion: completion
                    )
                }
            }
        } else {
            // 메인 해제하는 경우는 단순히 업데이트
            db.collection("KeyringBundle").document(documentId).updateData([
                "isMain": isMain
            ]) { [weak self] error in
                self?.handleMainBundleUpdateCompletion(
                    error: error,
                    bundle: bundle,
                    isMain: isMain,
                    currentMainBundles: [],
                    completion: completion
                )
            }
        }
    }
    
    //MARK: - 번들 이름 업데이트
    func updateBundleName(bundle: KeyringBundle, newName: String, completion: @escaping (Bool) -> Void) {
        guard let documentId = bundle.documentId else {
            completion(false)
            return
        }
        
        let trimmedName = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        db.collection("KeyringBundle").document(documentId).updateData([
            "name": trimmedName
        ]) { [weak self] error in
            if let error = error {
                completion(false)
                return
            }
            
            // 로컬 상태 업데이트
            DispatchQueue.main.async {
                if let index = self?.bundles.firstIndex(where: { $0.documentId == bundle.documentId }) {
                    self?.bundles[index].name = trimmedName
                }
                
                // selectedBundle도 같은 번들이면 업데이트
                if self?.selectedBundle?.documentId == bundle.documentId {
                    self?.selectedBundle?.name = trimmedName
                }
                completion(true)
            }
        }
    }
    
    private func handleMainBundleUpdateCompletion(
        error: Error?,
        bundle: KeyringBundle,
        isMain: Bool,
        currentMainBundles: [KeyringBundle],
        completion: @escaping (Bool) -> Void
    ) {
        if let error = error {
            print("메인 번들 업데이트 에러: \(error.localizedDescription)")
            completion(false)
            return
        }
        
        // 로컬 상태 업데이트
        DispatchQueue.main.async {
            // 기존 메인 번들들을 로컬에서도 해제
            for mainBundle in currentMainBundles {
                if let index = self.bundles.firstIndex(where: { $0.documentId == mainBundle.documentId }) {
                    self.bundles[index].isMain = false
                }
            }
            
            // 현재 번들 상태 업데이트
            if let index = self.bundles.firstIndex(where: { $0.documentId == bundle.documentId }) {
                self.bundles[index].isMain = isMain
                // selectedBundle도 같은 번들이면 업데이트
                if self.selectedBundle?.documentId == bundle.documentId {
                    self.selectedBundle?.isMain = isMain
                }
            }
            completion(true)
        }
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
    
    /// 뒷 카라비너 이미지 (또는 단일 카라비너 이미지)
    func backCarabinerImage(carabiner: Carabiner) -> some View {
        LazyImage(url: URL(string: carabiner.backImageURL)) { state in
            if let image = state.image {
                image
                    .resizable()
                    .scaledToFit()
            } else if state.isLoading {
                ProgressView()
            } else {
                Color.clear
            }
        }
    }
    
    /// 앞 카라비너 이미지 (햄버거 타입만)
    func frontCarabinerImage(carabiner: Carabiner) -> some View {
        Group {
            if let frontURL = carabiner.frontImageURL {
                LazyImage(url: URL(string: frontURL)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFit()
                    } else if state.isLoading {
                        ProgressView()
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    /// 배경 이미지 뷰
    var backgroundImage: some View {
        Group {
            if let bundle = selectedBundle,
               let bg = resolveBackground(from: bundle.selectedBackground) {
                LazyImage(url: URL(string: bg.backgroundImage)) { state in
                    if let image = state.image {
                        image
                            .resizable()
                            .scaledToFill()
                    } else if state.isLoading {
                        Color.clear
                    } else {
                        Color.clear
                    }
                }
            } else {
                Color.clear
            }
        }
    }
    
    // MARK: - 키링 편집 관련 공통 메서드들
    
    /// 선택된 키링들로부터 키링 데이터 리스트 생성 (편집용)
    func createKeyringDataListFromSelected(
        selectedKeyrings: [Int: Keyring],
        keyringOrder: [Int],
        carabiner: Carabiner
    ) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []
        
        // 추가된 순서대로 처리
        for index in keyringOrder {
            guard let keyring = selectedKeyrings[index] else { continue }
            let soundId = keyring.soundId
            
            // 커스텀 사운드 URL 처리
            let customSoundURL: URL? = {
                if soundId.hasPrefix("https://") || soundId.hasPrefix("http://") {
                    return URL(string: soundId)
                }
                return nil
            }()
            
            let particleId = keyring.particleId
            
            // 절대 좌표 사용 (이미 절대 좌표로 저장됨)
            let position = CGPoint(
                x: carabiner.keyringXPosition[index],
                y: carabiner.keyringYPosition[index]
            )
            
            let data = MultiKeyringScene.KeyringData(
                index: index,
                position: position,
                bodyImageURL: keyring.bodyImage,
                soundId: soundId,
                customSoundURL: customSoundURL,
                particleId: particleId
            )
            dataList.append(data)
        }
        
        return dataList
    }
    
    /// 뭉치에서 현재 키링들을 selectedKeyrings 형태로 변환
    func convertBundleToSelectedKeyrings(bundle: KeyringBundle) async -> ([Int: Keyring], [Int]) {
        var selectedKeyrings: [Int: Keyring] = [:]
        var keyringOrder: [Int] = []
        
        for (index, keyringId) in bundle.keyrings.enumerated() {
            guard keyringId != "none", !keyringId.isEmpty else { continue }
            
            // 사용자의 키링 목록에서 해당 키링 찾기 (documentId로 비교)
            if let keyring = self.keyring.first(where: { $0.documentId == keyringId }) {
                selectedKeyrings[index] = keyring
                keyringOrder.append(index)
            }
        }
        
        return (selectedKeyrings, keyringOrder)
    }
    
    /// selectedKeyrings를 뭉치 형태의 키링 배열로 변환
    func convertSelectedKeyringsToBundleFormat(
        selectedKeyrings: [Int: Keyring],
        maxKeyringCount: Int
    ) -> [String] {
        var keyrings = Array(repeating: "none", count: maxKeyringCount)
        
        for (index, keyring) in selectedKeyrings {
            if index < maxKeyringCount {
                keyrings[index] = keyring.documentId ?? "none"
            }
        }
        
        return keyrings
    }
    
    // MARK: - 카라비너 위치 계산
    
    /// 카라비너의 중심 위치를 계산 (이미지 로드 후 사용)
    /// - Parameters:
    ///   - carabiner: 카라비너 데이터
    ///   - imageSize: 실제 이미지 크기 (NukeUI의 PlatformImage.size)
    /// - Returns: 계산된 중심 위치
    func calculateCarabinerCenterPosition(
        for carabiner: Carabiner,
        imageSize: CGSize
    ) -> CGPoint {
        // X 좌표: 기존 방식 (왼쪽 상단 + 너비/2)
        let centerX = carabiner.carabinerX + (carabiner.carabinerWidth / 2)
        
        // Y 좌표: 이미지 비율을 고려하여 높이 계산 후 중심값
        let aspectRatio = imageSize.width / imageSize.height
        let scaledHeight = carabiner.carabinerWidth / aspectRatio
        let centerY = carabiner.carabinerY + (scaledHeight / 2)
        
        return CGPoint(x: centerX, y: centerY)
    }
    
    /// 일반적인 카라비너 비율을 사용한 근사치 계산
    /// (실제 이미지 로드 없이 빠른 계산이 필요한 경우)
    /// - Parameters:
    ///   - carabiner: 카라비너 데이터
    ///   - assumedAspectRatio: 가정하는 가로세로 비율 (기본값: 0.8 - 세로로 긴 형태)
    /// - Returns: 근사치 중심 위치
    func calculateApproximateCarabinerCenterPosition(
        for carabiner: Carabiner,
        assumedAspectRatio: CGFloat = 0.8
    ) -> CGPoint {
        let centerX = carabiner.carabinerX + (carabiner.carabinerWidth / 2)
        let approximateHeight = carabiner.carabinerWidth / assumedAspectRatio
        let centerY = carabiner.carabinerY + (approximateHeight / 2)
        
        return CGPoint(x: centerX, y: centerY)
    }
    
    // 캡쳐한 씬을 보여주는 메서드
    // BundleNameInputView, BundleNameEditView에서 사용하는 미리보기 씬
    @ViewBuilder
    func keyringSceneView() -> some View {
        let widthSize = screenWidth - 176
        let heightSize = widthSize * 7/5
        
        Group {
            if let imageData = bundleCapturedImage,
               let uiImage = UIImage(data: imageData) {
                // 캡처된 이미지 표시
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .offset(y: 30)
                    .clipped()
            } else {
                // 이미지가 없으면 기본 메시지 표시
                VStack {
                    Image(systemName: "photo")
                        .font(.system(size: 50))
                        .foregroundColor(.gray)
                    Text("이미지를 불러오는 중...")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(width: widthSize, height: heightSize)
        .clipped()
    }
    
    // MARK: - 번들 이미지 캐시 관리
    
    /// 캐시에서 번들 이미지를 로드하여 bundleCapturedImage에 설정
    /// - Parameter bundle: 로드할 번들
    /// - Returns: 로드 성공 여부
    @discardableResult
    func loadBundleImageFromCache(bundle: KeyringBundle) -> Bool {
        guard let documentId = bundle.documentId else {
            print("[CollectionViewModel] 번들 documentId가 없습니다.")
            return false
        }
        
        // BundleImageCache에서 이미지 로드
        if let imageData = BundleImageCache.shared.load(for: documentId) {
            self.bundleCapturedImage = imageData
            print("[CollectionViewModel] 캐시에서 번들 이미지 로드 성공: \(documentId)")
            return true
        } else {
            print("[CollectionViewModel] 캐시에 번들 이미지가 없습니다: \(documentId)")
            return false
        }
    }
}
