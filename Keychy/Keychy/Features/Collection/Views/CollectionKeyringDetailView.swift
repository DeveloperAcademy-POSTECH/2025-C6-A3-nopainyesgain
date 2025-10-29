//
//  CollectionKeyringDetailView.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI
import SpriteKit

struct CollectionKeyringDetailView: View {
    @State private var showInfoSheet: Bool = false
    
    let keyring: Keyring
    
    var body: some View {
        VStack {
            Text("키링 상세보기 화면")
            
            SpriteView(scene: createScene(keyring: keyring))
            
        }
        .navigationTitle(keyring.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    // 액션 추가
                }) {
                    Image(systemName: "ellipsis")
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private func createScene(keyring: Keyring) -> KeyringScene {
        let ringType = RingType.fromID(keyring.selectedRing)
        let chainType = ChainType.fromID(keyring.selectedChain)
        
        let scene = KeyringScene(
            ringType: ringType,
            chainType: chainType,
            bodyImageURL: keyring.bodyImage
        )
        scene.scaleMode = .aspectFill
        return scene
    }
        
}

// MARK: - 키링 씬
extension CollectionKeyringDetailView {
    
}

// MARK: - 하단 바텀시트
extension CollectionKeyringDetailView {
    
}
