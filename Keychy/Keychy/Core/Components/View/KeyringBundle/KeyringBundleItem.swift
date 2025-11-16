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
    let isInventoryView: Bool
    let geo: GeometryProxy

    @State private var cachedImage: Image?
    @State private var isCapturing: Bool = false
    // 임시 초기값, 함수에서 계산합니다
    @State private var widthSize: CGFloat = 0
    @State private var heightSize: CGFloat = 0

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
                    .frame(width: widthSize, height: heightSize)
                    .cornerRadius(10)

                if isInventoryView {
                    if bundle.isMain {
                        HStack {
                            Rectangle()
                                .fill(.mainOpacity80)
                                .overlay(
                                    Text("대표")
                                        .typography(.suit13M)
                                        .foregroundStyle(.white100)
                                )
                                .cornerRadius(20)
                                .frame(height: 24)
                                .frame(maxWidth: .infinity)
                        }
                        .padding(.horizontal, 10)
                        .padding(.top, 10)
                    }
                }
            }
            
            if isInventoryView {
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
            }
        }
        .onAppear {
            loadBundleImage()
            calculateWidthSize()
        }
    }
    // MARK: - 프레임 계산 메서드
    private func calculateWidthSize() {
        // 뭉치 보관함에서 쓰는 사이즈
        if isInventoryView {
            widthSize = ((geo.size.width - 52) / 2)
            heightSize = widthSize * 7/5
        } else {
            // 이름 입력 뷰에서 쓰는 사이즈
            widthSize = (geo.size.width - 176)
            heightSize = widthSize * 7/5
        }
        print("widthSize: \(widthSize), heightSize: \(heightSize)")
    }
    
    
    // MARK: - Bundle Image View

    private var bundleImageView: some View {
        return Group {
            if isCapturing {
                // 캡처 중 ProgressView
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                }
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
                bodyImageURL: keyringInfo.bodyImage
            )
            keyringDataList.append(data)
        }

        // 배경 이미지 미리 로드
        guard let _ = try? await StorageManager.shared.getImage(path: background.backgroundImage) else {
            await MainActor.run {
                isCapturing = false
            }
            return
        }
        
        // 모든 키링 bodyImage 미리 로드
        await withTaskGroup(of: Void.self) { group in
            for keyringData in keyringDataList {
                group.addTask {
                    _ = try? await StorageManager.shared.getImage(path: keyringData.bodyImageURL)
                }
            }
        }
        
        // 카라비너 이미지 미리 로드
        let carabinerType = CarabinerType.from(carabiner.carabinerType)
        if carabinerType == .hamburger {
            // hamburger 타입: back, front 모두 로드
            _ = try? await StorageManager.shared.getImage(path: carabiner.carabinerImage[1])
            _ = try? await StorageManager.shared.getImage(path: carabiner.carabinerImage[2])
        } else {
            // plain 타입: 하나만 로드
            _ = try? await StorageManager.shared.getImage(path: carabiner.carabinerImage[0])
        }
        
        let carabinerBackURL: String?
        let carabinerFrontURL: String?

        if carabinerType == .hamburger {
            carabinerBackURL = carabiner.carabinerImage[1]
            carabinerFrontURL = carabiner.carabinerImage[2]
        } else {
            // plain 타입
            carabinerBackURL = carabiner.carabinerImage[0]
            carabinerFrontURL = nil
        }

        if let pngData = await MultiKeyringCaptureScene.captureBundleImage(
            keyringDataList: keyringDataList,
            backgroundImageURL: background.backgroundImage,
            carabinerBackImageURL: carabinerBackURL,
            carabinerFrontImageURL: carabinerFrontURL,
            carabinerType: carabinerType,  // 카라비너 타입 전달
            carabinerX: carabiner.carabinerX,
            carabinerY: carabiner.carabinerY,
            carabinerWidth: carabiner.carabinerWidth,
        ) {
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
        } else {
            await MainActor.run {
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

            return KeyringInfo(id: keyringId, bodyImage: bodyImage)
        } catch {
            print("[BundleItem] 키링 정보 로드 실패: \(keyringId) - \(error.localizedDescription)")
            return nil
        }
    }

    /// 키링 정보 구조체 (최소 정보만)
    struct KeyringInfo {
        let id: String
        let bodyImage: String
    }
}
