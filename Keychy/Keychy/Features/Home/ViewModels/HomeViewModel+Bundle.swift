//
//  HomeViewModel+Bundle.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

import Foundation
import SwiftUI

extension HomeViewModel {
    
    // MARK: - Bundle Scene States
    @MainActor
    func resetBundleSceneStates() {
        didPrefetchBundle = false
        isBundleLoading = false
        isBundleSceneReady = false
        bundleScenePreparationDelay = false
        allBundleKeyringsStabilized = false
    }
    
    // MARK: - Bundle Scene Loading
    @MainActor
    func loadBundleScene() async {
        guard !didPrefetchBundle else { return }
        
        isBundleLoading = true
        
        // 1) 배경/카라비너 프리패치
        await collectionViewModel.loadBackgroundsAndCarabiners()
        
        // 2) 사용자 키링 보장 로드 (이미 있으면 스킵)
        if collectionViewModel.keyring.isEmpty {
            let uid = UserManager.shared.userUID
            if !uid.isEmpty {
                await withCheckedContinuation { continuation in
                    collectionViewModel.fetchUserKeyrings(uid: uid) { _ in
                        continuation.resume()
                    }
                }
            }
        }
        
        isBundleLoading = false
        didPrefetchBundle = true
        
        // 이미지 프리로드 및 씬 준비
        await preloadBundleImages()
    }
    
    @MainActor
    private func preloadBundleImages() async {
        guard let bundle = collectionViewModel.selectedBundle,
              let carabiner = resolveBundleCarabiner(from: bundle.selectedCarabiner),
              let backImageURL = carabiner.carabinerImage[safe: 1] else {
            return
        }
        
        // 카라비너 이미지와 키링 바디 이미지들을 모두 프리로드
        Task {
            do {
                // 1. 카라비너 이미지 로드
                let _ = try await StorageManager.shared.getImage(path: backImageURL)
                print("[HomeViewModel+Bundle] Carabiner image loaded")
                
                // 2. 모든 키링 바디 이미지들 프리로드
                let dataList = createBundleKeyringDataList(carabiner: carabiner, geometry: CGSize(width: 400, height: 800))
                for keyringData in dataList {
                    if !keyringData.bodyImageURL.isEmpty {
                        do {
                            let _ = try await StorageManager.shared.getImage(path: keyringData.bodyImageURL)
                            print("[HomeViewModel+Bundle] Preloaded keyring image: \(keyringData.index)")
                        } catch {
                            print("[HomeViewModel+Bundle] Failed to preload keyring \(keyringData.index): \(error)")
                        }
                    }
                }
                
                await MainActor.run {
                    self.isBundleSceneReady = true
                    print("[HomeViewModel+Bundle] All images preloaded, scene ready!")
                    
                    // 모든 이미지가 로드된 후 짧은 안정화 시간
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.bundleScenePreparationDelay = true
                        }
                        
                        // 키링 씬이 자체적으로 안정화를 관리하므로 짧은 추가 대기만
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                self.allBundleKeyringsStabilized = true
                                print("[HomeViewModel+Bundle] Scene ready to display!")
                            }
                        }
                    }
                }
            } catch {
                print("[HomeViewModel+Bundle] Failed to preload images: \(error)")
                await MainActor.run {
                    self.isBundleSceneReady = true
                    
                    // 실패 시 더 긴 대기 시간
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                        withAnimation(.easeInOut(duration: 0.5)) {
                            self.bundleScenePreparationDelay = true
                        }
                        
                        // 실패 케이스에서도 간단한 대기
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                self.allBundleKeyringsStabilized = true
                                print("[HomeViewModel+Bundle] Scene ready (error case)")
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Bundle Resolve Helpers
    func resolveBundleCarabiner(from id: String) -> Carabiner? {
        collectionViewModel.carabiners.first { $0.id == id }
    }
    
    func resolveBundleBackground(from id: String) -> Background? {
        collectionViewModel.backgrounds.first { $0.id == id }
    }
    
    /// Firestore 문서 id -> Keyring 모델 해석
    func resolveBundleKeyring(from documentId: String) -> Keyring? {
        let result = collectionViewModel.keyring.first { kr in
            collectionViewModel.keyringDocumentIdByLocalId[kr.id] == documentId
        }
        print("[HomeViewModel+Bundle] resolveKeyring for docId=\(documentId): \(result?.name ?? "nil")")
        return result
    }
    
    // MARK: - Bundle KeyringData Creation
    /// 번들에 저장된 문서 id 배열을 기반으로 MultiKeyringScene.KeyringData 배열 생성
    func createBundleKeyringDataList(
        carabiner: Carabiner,
        geometry: CGSize
    ) -> [MultiKeyringScene.KeyringData] {
        var dataList: [MultiKeyringScene.KeyringData] = []
        
        guard let bundle = collectionViewModel.selectedBundle else {
            return dataList
        }
        
        // bundle.keyrings 배열을 순회 (각 인덱스는 카라비너 위치)
        for index in 0..<carabiner.maxKeyringCount {
            // 번들에 저장된 문서 id (없으면 "none")
            let docId = bundle.keyrings[safe: index] ?? "none"
            if docId == "none" || docId.isEmpty {
                print("[HomeViewModel+Bundle] dataList skip carabinerPos=\(index) (no keyring)")
                continue
            }
            
            guard let keyring = resolveBundleKeyring(from: docId) else {
                print("[HomeViewModel+Bundle] dataList skip carabinerPos=\(index) (keyring not found for docId=\(docId))")
                continue
            }
            
            print("[HomeViewModel+Bundle] dataList add carabinerPos=\(index)")
            print("[HomeViewModel+Bundle] keyring: name=\(keyring.name), body=\(keyring.bodyImage)")
            print("[HomeViewModel+Bundle] sound=\(keyring.soundId), particle=\(keyring.particleId)")
            print("[HomeViewModel+Bundle] position: x=\(carabiner.keyringXPosition[index]), y=\(carabiner.keyringYPosition[index])")
            
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
        print("[HomeViewModel+Bundle] dataList count = \(dataList.count)")
        
        return dataList
    }
    
    // MARK: - Bundle Background Image
    func getBundleBackgroundImageURL() -> String? {
        guard let bundle = collectionViewModel.selectedBundle,
              let bg = resolveBundleBackground(from: bundle.selectedBackground) else {
            return nil
        }
        return bg.backgroundImage
    }
}
