//
//  MultiKeyringSceneView.swift
//  Keychy
//
//  Created by Assistant on 11/05/25.
//

import SwiftUI
import SpriteKit

/// 여러 키링을 하나의 씬에 표시하는 SwiftUI View
struct MultiKeyringSceneView: View {
    let keyringDataList: [MultiKeyringScene.KeyringData]
    let ringType: RingType
    let chainType: ChainType
    let backgroundColor: UIColor

    @State private var scene: MultiKeyringScene?

    init(
        keyringDataList: [MultiKeyringScene.KeyringData],
        ringType: RingType = .basic,
        chainType: ChainType = .basic,
        backgroundColor: UIColor = .clear
    ) {
        self.keyringDataList = keyringDataList
        self.ringType = ringType
        self.chainType = chainType
        self.backgroundColor = backgroundColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let scene = scene {
                    SpriteView(scene: scene, options: [.allowsTransparency])
                        .ignoresSafeArea()
                } else {
                    Color.clear
                }
            }
            .onAppear {
                setupScene(size: geometry.size)
            }
            .onChange(of: keyringDataList) { _, _ in
                setupScene(size: geometry.size)
            }
        }
    }

    private func setupScene(size: CGSize) {
        let newScene = MultiKeyringScene(
            keyringDataList: keyringDataList,
            ringType: ringType,
            chainType: chainType,
            backgroundColor: backgroundColor
        )

        newScene.size = size
        newScene.scaleMode = .resizeFill

        self.scene = newScene
    }
}
