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

    var body: some View {
        ZStack {
            // SpriteView 표시 (캐시 여부와 관계없이 항상 표시)
            SpriteView(
                scene: createMiniScene(keyring: keyring)
            )

            if isLoading {
                Color.black20
                    .overlay {
                        VStack(spacing: 8) {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .gray))
                                .scaleEffect(1.2)

                            Text("키링을 가져오는 중...")
                                .typography(.suit12M)
                                .foregroundColor(.white)
                        }
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
    }
    
    // MARK: - 상태 오버레이
    private func statusOverlay(info: String) -> some View {
        RoundedRectangle(cornerRadius: 10)
            .fill(.black20)
            .overlay {
                VStack {
                    ZStack {
                        UnevenRoundedRectangle(
                            topLeadingRadius: 10,
                            topTrailingRadius: 10
                        )
                        .fill(Color.black60)
                        .frame(height: 26)
                        
                        Text(info)
                            .typography(.suit13M)
                            .foregroundColor(.white100)
                            .frame(height: 26)
                    }
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
        let keyringID = keyring.id.uuidString
        print("🔍 [CollectionCell] 키링 캐시 확인: \(keyringID)")

        // 캐시가 이미 있으면 스킵
        if KeyringImageCache.shared.exists(for: keyringID) {
            print("⏭️ [CollectionCell] 캐시 이미 존재, 캡처 스킵: \(keyringID)")
            return
        }

        print("📸 [CollectionCell] 캐시 없음, 백그라운드 캡처 시작: \(keyringID)")

        // 캐시 없으면 백그라운드에서 조용히 캡처
        Task.detached(priority: .userInitiated) {
            await captureAndCache(keyringID: keyringID)
        }
    }

    // MARK: - 백그라운드 캡처 + 캐싱 (위젯용)

    /// 백그라운드에서 Scene 캡처 후 캐시 저장 (UI 업데이트 없음)
    private func captureAndCache(keyringID: String) async {
        print("🎬 [CollectionCell] 위젯용 이미지 캡처 시작 (백그라운드): \(keyringID)")

        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)

        // Scene 생성 (onLoadingComplete 없이)
        let scene = KeyringCellScene(
            ringType: ringType,
            chainType: chainType,
            bodyImage: keyring.bodyImage,
            targetSize: CGSize(width: 175, height: 233),
            zoomScale: 2.0
        )
        scene.scaleMode = .aspectFill

        // PNG 캡처
        if let pngData = await scene.captureToPNG() {
            print("✅ [CollectionCell] 캡처 완료, 위젯용 이미지 저장 중: \(keyringID)")

            // FileManager 캐시에 저장 (위젯에서 접근 가능)
            KeyringImageCache.shared.save(pngData: pngData, for: keyringID)

            print("💾 [CollectionCell] 위젯용 이미지 저장 완료: \(keyringID)")
        } else {
            print("❌ [CollectionCell] 캡처 실패: \(keyringID)")
        }
    }
}
