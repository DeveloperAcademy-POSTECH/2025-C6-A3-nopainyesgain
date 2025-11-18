//
//  KeyringBundleItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

// 뭉치 보관함 그리드에 들어가는 각각의 아이템 컴포넌트입니다
import SwiftUI
import SpriteKit
import FirebaseFirestore

struct KeyringBundleItem: View {
    let bundle: KeyringBundle
    
    @State private var cachedImage: Image?
    @State private var isCapturing: Bool = false
    
    // 고정 캡처 크기 (iPhone 14 기준)
    private let captureSize = CGSize(width: 390, height: 844)
    
    // 실제로 걸린 키링 개수 (none과 빈 문자열 제외)
    private var actualKeyringCount: Int {
        bundle.keyrings.filter { $0 != "none" && !$0.isEmpty }.count
    }
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .top) {
                // 캐시된 번들 이미지 표시
                bundleImageView
                    .frame(width: twoGrid5to7CellWidth, height: twoGrid5to7CellHeight)
                    .cornerRadius(10)
                
                if bundle.isMain {
                    HStack {
                        Spacer()
                        Image(.starFillMain500)
                            .padding(6.53)
                            .background(
                                Circle()
                                    .fill(.white50)
                                    .glassEffect(.regular.interactive(), in: .circle)
                            )
                    }
                    .padding(10)
                }
            }
            HStack {
                Text(bundle.name)
                    .typography(.notosans15M)
                    .foregroundStyle(.black100)
                Spacer()
            }
            
            HStack {
                Text("걸린 키링")
                    .typography(.suit12M)
                    .foregroundStyle(.gray500)
                Spacer()
                Text("\(actualKeyringCount) / \(bundle.maxKeyrings) 개")
                    .typography(.suit12M)
                    .foregroundStyle(.main500)
            }
        } //: VSTACK
        .onAppear {
            loadBundleImage()
        }
    }
}

extension KeyringBundleItem {
    // MARK: - Bundle Image View

    private var bundleImageView: some View {
        return Group {
            if isCapturing {
                // 캡처 중 ProgressView
                LoadingAlert(type: .short, message: nil)
            } else if let cachedImage = cachedImage {
                cachedImage
                    .resizable()
                    .scaledToFill()
                    .offset(y: 30)   // 아래로 30pt 이동
                    .clipped()
            }
        }
    }

    // MARK: - Load Bundle Image

    /// 캐시에서 번들 이미지 로드
    private func loadBundleImage() {
        guard let documentId = bundle.documentId else {
            return
        }
        
        // 캐시에서 이미지 로드
        if let imageData = BundleImageCache.shared.load(for: documentId),
           let uiImage = UIImage(data: imageData) {
            cachedImage = Image(uiImage: uiImage)
        } else {
            // 캐시가 없으면 다시 캡처
            Task {
                await recaptureAndCacheBundleImage(bundleId: documentId, bundleName: bundle.name)
            }
        }
    }

    // MARK: - Recapture Bundle Image

    /// 번들 이미지 재캡처 및 캐시 저장
    private func recaptureAndCacheBundleImage(bundleId: String, bundleName: String) async {
        await MainActor.run {
            isCapturing = true
        }
        
        // Firestore에서 번들 정보 가져오기 (배경, 카라비너, 키링 정보)
        guard let background = await fetchBackgroundInfo(backgroundId: bundle.selectedBackground),
              let carabiner = await fetchCarabinerInfo(carabinerId: bundle.selectedCarabiner) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        // 키링 데이터 생성 (원본 index 유지)
        var keyringDataList: [MultiKeyringCaptureScene.KeyringData] = []
        
        for (originalIndex, keyringId) in bundle.keyrings.enumerated() {
            // "none"이나 빈 문자열은 건너뛰기
            guard keyringId != "none" && !keyringId.isEmpty else {
                continue
            }
            
            // index 범위 체크
            guard originalIndex < carabiner.keyringXPosition.count,
                  originalIndex < carabiner.keyringYPosition.count else {
                continue
            }
            
            // Firebase에서 키링 정보 가져오기
            guard let keyringInfo = await fetchKeyringFromFirestore(keyringId: keyringId) else {
                continue
            }
            
            let data = MultiKeyringCaptureScene.KeyringData(
                index: originalIndex,
                position: CGPoint(
                    x: carabiner.keyringXPosition[originalIndex],
                    y: carabiner.keyringYPosition[originalIndex]
                ),
                bodyImageURL: keyringInfo.bodyImage,
                hookOffsetY: keyringInfo.hookOffsetY
            )
            keyringDataList.append(data)
        }
        
        // 카라비너 타입 및 URL 준비
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        let carabinerBackURL: String?
        let carabinerFrontURL: String?
        
        if carabinerType == .hamburger {
            carabinerBackURL = carabiner.carabinerImage[1]
            carabinerFrontURL = carabiner.carabinerImage[2]
        } else {
            carabinerBackURL = carabiner.carabinerImage[0]
            carabinerFrontURL = nil
        }
        
        guard let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth
        ) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        // BundleImageCache에 저장
        BundleImageCache.shared.syncBundle(
            id: bundleId,
            name: bundleName,
            imageData: pngData
        )
        
        // UI 업데이트
        if let uiImage = UIImage(data: pngData) {
            await MainActor.run {
                cachedImage = Image(uiImage: uiImage)
                isCapturing = false
            }
        }
    }

    // MARK: - Fetch Helper Methods

    /// 배경 정보 가져오기
    private func fetchBackgroundInfo(backgroundId: String) async -> Background? {
        // WorkshopDataManager에서 배경 정보 가져오기
        await WorkshopDataManager.shared.fetchBackgroundsIfNeeded()
        return WorkshopDataManager.shared.backgrounds.first { $0.id == backgroundId }
    }

    /// 카라비너 정보 가져오기
    private func fetchCarabinerInfo(carabinerId: String) async -> Carabiner? {
        // WorkshopDataManager에서 카라비너 정보 가져오기
        await WorkshopDataManager.shared.fetchCarabinersIfNeeded()
        return WorkshopDataManager.shared.carabiners.first { $0.id == carabinerId }
    }

    /// Firestore에서 키링 정보 가져오기
    private func fetchKeyringFromFirestore(keyringId: String) async -> KeyringInfo? {
        do {
            let db = FirebaseFirestore.Firestore.firestore()
            let document = try await db.collection("Keyring").document(keyringId).getDocument()
            
            guard let data = document.data(),
                  let bodyImage = data["bodyImage"] as? String else {
                return nil
            }

            let hookOffsetY = data["hookOffsetY"] as? CGFloat ?? 0.0

            return KeyringInfo(id: keyringId, bodyImage: bodyImage, hookOffsetY: hookOffsetY)
        } catch {
            print("[BundleItem] 키링 정보 로드 실패: \(keyringId) - \(error.localizedDescription)")
            return nil
        }
    }
}

/// 키링 정보 구조체 (최소 정보만)
struct KeyringInfo {
    let id: String
    let bodyImage: String
    let hookOffsetY: CGFloat?
}

