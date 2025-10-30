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
}
