//
//  KeyringCollectView+Alerts.swift
//  Keychy
//
//  Created by Jini on 1/9/26.
//

import SwiftUI

// MARK: - 알럿/팝업 관련
extension KeyringCollectView {
    @ViewBuilder
    func alertOverlayView(geometry: GeometryProxy) -> some View {
        if viewModel.shouldApplyBlur {
            Color.black20
                .ignoresSafeArea()
                .zIndex(99)
            
            if viewModel.isAccepting {
                loadingOverlay(geometry: geometry)
            }
            
            if viewModel.showAcceptCompleteAlert {
                acceptCompleteAlert(geometry: geometry)
            }
            
            if viewModel.showInvenFullAlert {
                invenFullAlert(geometry: geometry)
            }
        }
    }
    
    private func loadingOverlay(geometry: GeometryProxy) -> some View {
        LoadingAlert(type: .short, message: nil)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            .zIndex(101)
    }
    
    private func acceptCompleteAlert(geometry: GeometryProxy) -> some View {
        KeychyAlert(
            type: .addToCollection,
            message: "키링이 내 보관함에 추가되었어요!",
            isPresented: $viewModel.showAcceptCompleteAlert
        )
        .position(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
        .zIndex(101)
    }
    
    private func invenFullAlert(geometry: GeometryProxy) -> some View {
        InvenLackPopup(isPresented: $viewModel.showInvenFullAlert)
            .position(
                x: geometry.size.width / 2,
                y: geometry.size.height / 2
            )
            .zIndex(100)
    }
}
