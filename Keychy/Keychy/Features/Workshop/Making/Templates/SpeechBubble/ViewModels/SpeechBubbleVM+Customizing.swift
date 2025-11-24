//
//  SpeechBubbleVM+Customizing.swift
//  Keychy
//
//  Created by 길지훈 on 11/23/25.
//

import SwiftUI

extension SpeechBubbleVM {
    
    // MARK: - Lifecycle Callbacks
    
    func onModeChanged(from oldMode: CustomizingMode, to newMode: CustomizingMode) {
        if oldMode == .frame && newMode != .frame {
            Task {
                await composeTextWithFrame()
            }
        }
    }
    
    func beforeNavigateToNext() {
        Task {
            await composeTextWithFrame()
        }
    }
    
    // MARK: - Scene View Provider
    
    func sceneView(for mode: CustomizingMode, onSceneReady: @escaping () -> Void) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(KeyringSceneView(viewModel: self, onSceneReady: onSceneReady))
        case .frame:
            return AnyView(SpeechBubbleFramePreviewView(viewModel: self, onSceneReady: onSceneReady))
        default:
            return AnyView(EmptyView())
        }
    }
    
    func bottomContentView(
        for mode: CustomizingMode,
        showPurchaseSheet: Binding<Bool>,
        cartItems: Binding<[EffectItem]>
    ) -> AnyView {
        switch mode {
        case .effect:
            return AnyView(EffectSelectorView(viewModel: self, cartItems: cartItems))
        case .frame:
            return AnyView(SpeechBubbleFrameSelectorView(viewModel: self))
        default:
            return AnyView(EmptyView())
        }
    }
    
    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .frame:
            return 0.38  // 프레임 + 컬러 섹션
        case .effect:
            return 0.3
        default:
            return 0.35
        }
    }
}
