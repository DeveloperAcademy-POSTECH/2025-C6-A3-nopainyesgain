//
//  CarabinerSceneView.swift
//  KeytschPrototype
//
//  Created by Assistant on 10/30/25.
//

import SwiftUI
import SpriteKit

/// CarabinerScene을 SwiftUI에서 사용하기 위한 래퍼 뷰
struct CarabinerSceneView: View {
    
    // MARK: - Properties
    let carabiner: Carabiner?
    let carabinerImage: UIImage?
    let bodyImages: [UIImage]
    
    @State private var scene: CarabinerScene?
    @State private var isSceneReady = false
    @State private var screenWidth: CGFloat = 0
    
    // MARK: - Callbacks
    var onSceneReady: (() -> Void)?
    var onKeyringTapped: ((Int) -> Void)?
    
    // MARK: - Init
    init(
        carabiner: Carabiner? = nil,
        carabinerImage: UIImage? = nil,
        bodyImages: [UIImage] = [],
        onSceneReady: (() -> Void)? = nil,
        onKeyringTapped: ((Int) -> Void)? = nil
    ) {
        self.carabiner = carabiner
        self.carabinerImage = carabinerImage
        self.bodyImages = bodyImages
        self.onSceneReady = onSceneReady
        self.onKeyringTapped = onKeyringTapped
    }
    
    // MARK: - Body
    var body: some View {
        GeometryReader { geometry in
            SpriteView(scene: createScene(for: geometry.size))
                .onAppear {
                    screenWidth = geometry.size.width
                }
                .overlay {
                    if !isSceneReady {
                        LoadingOverlay()
                    }
                }
        }
    }
    
    // MARK: - Scene Creation
    private func createScene(for size: CGSize) -> CarabinerScene {
        if let existingScene = scene {
            return existingScene
        }
        
        let newScene = CarabinerScene(
            carabiner: carabiner,
            carabinerImage: carabinerImage,
            bodyImages: bodyImages,
            targetSize: size,
            screenWidth: screenWidth > 0 ? screenWidth : size.width
        )
        
        // 콜백 설정
        newScene.onSceneReady = { [weak newScene] in
            DispatchQueue.main.async {
                self.isSceneReady = true
                self.onSceneReady?()
            }
        }
        
        scene = newScene
        return newScene
    }
}

// MARK: - Loading Overlay
private struct LoadingOverlay: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.2)
                .progressViewStyle(CircularProgressViewStyle(tint: .primary))
            
            Text("키링을 준비하고 있어요...")
                .font(.caption)
                .foregroundColor(.gray500)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.1))
        .transition(.opacity)
    }
}
