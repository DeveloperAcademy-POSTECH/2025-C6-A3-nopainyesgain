//
//  CollectionCellView.swift
//  Keychy
//
//  Created by Jini on 10/30/25.
//

import SwiftUI
import SpriteKit

struct CollectionCellView: View {
    let keyring: Keyring
    @State private var isLoading: Bool = true
    @State private var cachedImage: UIImage?
    @State private var scene: KeyringCellScene?
    @State private var captureTask: Task<Void, Never>?
    @State private var backgroundObserver: NSObjectProtocol?

    var body: some View {
        ZStack {
            Color.gray50
            
            infoContent

            if isLoading && cachedImage == nil {
                Color.gray50
                    .overlay {
                        LoadingAlert(type: .short, message: nil)
                            .scaleEffect(0.7)
                    }
            }

            // 비활성 상태 오버레이 (포장중, 출품중)
            if let info = keyring.status.overlayInfo {
                statusOverlay(info: info)
            }
        }
        .onAppear {
            loadContent()
        }
        .onDisappear {
            if let keyringID = keyring.documentId {
                Task {
                    await KeyringCacheManager.shared.cancelTask(for: keyringID)
                }
            }
            cleanupScene()
        }
    }
    
    @ViewBuilder
    private var infoContent: some View {
        if let cachedImage = cachedImage {
            // 캐시된 이미지 표시
            Image(uiImage: cachedImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let scene = scene {
            // Scene 표시
            SpriteView(scene: scene)
                .onAppear {
                    scene.isPaused = false
                }
                .onDisappear {
                    scene.isPaused = true
                }
        } else {
            // 로딩 전 기본 배경
            Color.gray50
        }
    }
    
    // 컨텐츠 로딩
    private func loadContent() {
        guard let keyringID = keyring.documentId else {
            // documentId 없으면 Scene만 생성
            createSceneIfNeeded()
            return
        }
        
        // 위젯 메타데이터 동기화
        syncWidgetMetadata(keyringID: keyringID)
        
        // 1. 캐시 확인
        if let imageData = KeyringImageCache.shared.load(for: keyringID, type: .thumbnail),
           !imageData.isEmpty,
           let image = UIImage(data: imageData),
           !ImageValidator.isBlankImage(image) {
            self.cachedImage = image
            self.isLoading = false
            return
        }
        
        // 2. 유효하지 않은, 손상된 캐시 삭제
        if KeyringImageCache.shared.exists(for: keyringID, type: .thumbnail) {
            KeyringImageCache.shared.delete(for: keyringID, type: .thumbnail)
        }
        
        // 3. 캐시 없으면 Scene 생성
        createSceneIfNeeded()
        
        // 4. 캡처
        Task {
            await KeyringCacheManager.shared.requestCapture(keyring: keyring)
        }
    }
    
    private func createSceneIfNeeded() {
        guard scene == nil else { return }
        
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        let newScene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            templateId: keyring.selectedTemplate,
            targetSize: CGSize(width: 175, height: 233),
            zoomScale: 2.0,
            hookOffsetY: keyring.hookOffsetY,
            chainLength: keyring.chainLength,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        )
        newScene.scaleMode = .aspectFill
        self.scene = newScene
    }
    
    private func cleanupScene() {
        scene?.removeAllChildren()
        scene?.removeAllActions()
        scene?.physicsWorld.removeAllJoints()
        scene?.view?.presentScene(nil)
        scene = nil
    }
    
    // MARK: - 상태 오버레이
    private func statusOverlay(info: String) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.black50)
            .overlay {
                VStack {
                    Text(info)
                        .typography(.suit13M)
                        .foregroundColor(.white100)
                        .padding(.vertical, 4)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color.black60)
                                .frame(height: 26)
                        )
                    
                    Spacer()
                }
                .padding(5)
            }
    }

    // MARK: - 위젯 메타데이터 동기화
    private func syncWidgetMetadata(keyringID: String) {
        var keyrings = KeyringImageCache.shared.loadAvailableKeyrings()
        let isInMetadata = keyrings.contains(where: { $0.id == keyringID })
        let shouldBeInWidget = !keyring.isPackaged && !keyring.isPublished
        
        if shouldBeInWidget && !isInMetadata {
            // 위젯에 있어야 하는데 없음 → 추가
            if let imageData = KeyringImageCache.shared.load(for: keyringID, type: .thumbnail) {
                KeyringImageCache.shared.syncKeyring(
                    id: keyringID,
                    name: keyring.name,
                    imageData: imageData
                )
            }
        } else if !shouldBeInWidget && isInMetadata {
            // 위젯에 없어야 하는데 있음 → 제거
            keyrings.removeAll { $0.id == keyringID }
            KeyringImageCache.shared.saveAvailableKeyrings(keyrings)
        }
    }

    // MARK: - 백그라운드 캡처 + 캐싱 (위젯용)

    /// 백그라운드에서 Scene 캡처 후 캐시 저장 (UI 업데이트 없음)
    private func captureAndCache(keyringID: String, retryCount: Int = 0) async {
        // 실패 시 재시도 횟수
        let maxRetries = 3
        
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        await withCheckedContinuation { continuation in
            // 이미지 로딩 완료 콜백
            var loadingCompleted = false

            // Scene 생성 (onLoadingComplete 콜백 추가, 투명 배경)
            let scene = KeyringCellScene(
                ringType: ringType,
                chainType: chainType,
                bodyImage: keyring.bodyImage,
                templateId: keyring.selectedTemplate,
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
                hookOffsetY: keyring.hookOffsetY,
                chainLength: keyring.chainLength,
                onLoadingComplete: {
                    loadingCompleted = true
                }
            )
            scene.scaleMode = .aspectFill

            // SKView 생성 및 Scene 표시 (렌더링 시작)
            let view = SKView(frame: CGRect(origin: .zero, size: scene.size))
            view.allowsTransparency = true
            view.presentScene(scene)

            // 로딩 완료 대기 (최대 3초)
            Task {
                var waitTime = 0.0
                let checkInterval = 0.1 // 100ms마다 체크
                let maxWaitTime = 5.0   // 최대 5초
                
                // Task 취소 체크
                while !loadingCompleted && waitTime < maxWaitTime {
                    // 취소되었으면 즉시 종료
                    if Task.isCancelled {
                        print("취소됨 (로딩 중): \(keyringID)")
                        continuation.resume()
                        return
                    }
                    
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }

                // 타임아웃 체크 - 로딩 완료되지 않았으면 캡처하지 않음
                if !loadingCompleted {
                    print("[CollectionCell] 타임아웃 - 로딩 미완료: \(keyringID)")
                    
                    // 재시도
                    if retryCount < maxRetries {
                        print("[CollectionCell] 재시도 중... (\(retryCount + 1)/\(maxRetries))")
                        Task.detached(priority: .userInitiated) {
                            try? await Task.sleep(for: .seconds(0.5))
                            await self.captureAndCache(keyringID: keyringID, retryCount: retryCount + 1)
                        }
                    } else {
                        print("[CollectionCell] 최종 실패 - 타임아웃: \(keyring.name)")
                    }
                    
                    continuation.resume()
                    return
                }
                
                // 캡처 전 테스크 취소 체크
                if Task.isCancelled {
                    print("취소됨 (캡처 직전): \(keyringID)")
                    continuation.resume()
                    return
                }
                
                // 로딩 완료 후 추가 렌더링 대기 (200ms)
                try? await Task.sleep(for: .seconds(0.2))
                
                // PNG 캡처 전 최종 취소 체크
                guard !Task.isCancelled else {
                    print("취소됨 (렌더링 대기 후): \(keyringID)")
                    continuation.resume()
                    return
                }
                
                // PNG 캡처
                if let pngData = await scene.captureToPNG(),
                   !pngData.isEmpty,
                   let image = UIImage(data: pngData),
                   image.size.width > 0,
                   image.size.height > 0,
                   !ImageValidator.isBlankImage(image) {
                    
                    // 저장 직전 취소 체크
                    guard !Task.isCancelled else {
                        print("취소됨 (저장 직전): \(keyringID)")
                        continuation.resume()
                        return
                    }
                    
                    // FileManager 캐시에 저장 (위젯에서 접근 가능)
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringID, type: .thumbnail)

                    if !keyring.isPackaged && !keyring.isPublished {
                        KeyringImageCache.shared.syncKeyring(
                            id: keyringID,
                            name: keyring.name,
                            imageData: pngData
                        )
                    } else {
                        print("[CollectionCell] 캡처 성공 (위젯 제외): \(keyringID)")
                    }
                } else {
                    print("[CollectionCell] 캡처 실패 - 유효하지 않은 데이터: \(keyringID)")
                    
                    // 재시도
                    if retryCount < maxRetries {
                        print("[CollectionCell] 재시도 중... (\(retryCount + 1)/\(maxRetries))")
                        Task.detached(priority: .userInitiated) {
                            try? await Task.sleep(for: .seconds(0.5))
                            await self.captureAndCache(keyringID: keyringID, retryCount: retryCount + 1)
                        }
                    }
                }

                continuation.resume()
            }
        }
    }
}
