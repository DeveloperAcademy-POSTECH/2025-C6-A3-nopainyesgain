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
            // TODO: 이슈 #2에서 FramePreviewView 구현
            return AnyView(EmptyView())
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
            // TODO: 이슈 #2에서 FrameSelectorView 구현
            return AnyView(EmptyView())
        default:
            return AnyView(EmptyView())
        }
    }
    
    func bottomViewHeightRatio(for mode: CustomizingMode) -> CGFloat {
        switch mode {
        case .frame:
            return 0.35
        case .effect:
            return 0.3
        default:
            return 0.35
        }
    }
}
