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
    @State private var scene: KeyringCellScene?

    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene)
                    .onAppear {
                        scene.isPaused = false
                    }
                    .onDisappear {
                        scene.isPaused = true
                    }
            } else {
                Color.gray50
                    .onAppear {
                        createSceneIfNeeded()
                    }
            }

            if isLoading {
                Color.gray50
                    .overlay {
                        LoadingAlert(type: .short, message: nil)
                            .scaleEffect(0.5)
                    }
            }

            // 로딩 완료되면 상태도 오버레이
            if !isLoading, let info = keyring.status.overlayInfo {
                statusOverlay(info: info)
            }
        }
        .onAppear {
            checkAndCaptureKeyring()
        }
        .onDisappear {
            cleanupScene()
        }
    }
    
    private func createSceneIfNeeded() {
        guard scene == nil else { return }
        
        scene = createMiniScene(keyring: keyring)
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
            .fill(.black20)
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
                        .padding(.top, 8)
                        .padding(.horizontal, 8)
                    
                    Spacer()
                }
            }
    }
    
    private func createMiniScene(keyring: Keyring) -> KeyringCellScene {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        let scene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: CGSize(width: 175, height: 233),
            zoomScale: 2.0,
            hookOffsetY: keyring.hookOffsetY,
            onLoadingComplete: {
                DispatchQueue.main.async {
                    withAnimation {
                        self.isLoading = false
                    }
                }
            }
        )
        scene.scaleMode = .aspectFill
        return scene
    }

    // MARK: - 캐시 확인 및 백그라운드 캡처 (UI 업데이트 없음)

    /// 캐시 확인 후 없으면 백그라운드에서 캡처만 수행 (위젯용)
    private func checkAndCaptureKeyring() {
        // Firestore documentId가 없으면 캐싱 불가
        guard let keyringID = keyring.documentId else {
            return
        }

        // 포장된 키링이면 캐시 삭제 (위젯 목록에서 제거)
        if keyring.isPackaged {
            if KeyringImageCache.shared.exists(for: keyringID) {
                KeyringImageCache.shared.removeKeyring(id: keyringID)
                print("[CollectionCell] 포장된 키링 캐시 삭제: \(keyring.name) (\(keyringID))")
            }
            return
        }

        // 캐시가 이미 있으면 스킵
        if KeyringImageCache.shared.exists(for: keyringID) {
            return
        }

        // 캐시 없으면 백그라운드에서 조용히 캡처
        Task.detached(priority: .userInitiated) {
            await captureAndCache(keyringID: keyringID)
        }
    }

    // MARK: - 백그라운드 캡처 + 캐싱 (위젯용)

    /// 백그라운드에서 Scene 캡처 후 캐시 저장 (UI 업데이트 없음)
    private func captureAndCache(keyringID: String) async {
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
                targetSize: CGSize(width: 175, height: 233),
                customBackgroundColor: .clear,
                zoomScale: 2.0,
                hookOffsetY: keyring.hookOffsetY,
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
                let maxWaitTime = 3.0   // 최대 3초

                while !loadingCompleted && waitTime < maxWaitTime {
                    try? await Task.sleep(nanoseconds: UInt64(checkInterval * 1_000_000_000))
                    waitTime += checkInterval
                }

                if !loadingCompleted {
                    print("[CollectionCell] 타임아웃 - 로딩 미완료: \(keyringID)")
                } else {
                    // 로딩 완료 후 추가 렌더링 대기 (200ms)
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }

                // PNG 캡처
                if let pngData = await scene.captureToPNG() {
                    // FileManager 캐시에 저장 (위젯에서 접근 가능)
                    KeyringImageCache.shared.save(pngData: pngData, for: keyringID)

                    // App Group에 위젯용 이미지 및 메타데이터 동기화
                    KeyringImageCache.shared.syncKeyring(
                        id: keyringID,
                        name: keyring.name,
                        imageData: pngData
                    )
                } else {
                    print("❌ [CollectionCell] 캡처 실패: \(keyringID)")
                }

                continuation.resume()
            }
        }
    }
}
