//
//  KeyringReceiveView+Alerts.swift
//  Keychy
//
//  Created by Jini on 1/9/26.
//

import SwiftUI

// MARK: - 알럿/팝업 관련
extension KeyringReceiveView {
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
            
            if viewModel.showAlreadyAcceptedAlert {
                alreadyAcceptedAlert(geometry: geometry)
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
    
    private func alreadyAcceptedAlert(geometry: GeometryProxy) -> some View {
        KeychyAlert(
            type: .fail,
            message: "이미 누군가 받은 키링이에요",
            isPresented: $viewModel.showAlreadyAcceptedAlert
        )
        .position(
            x: geometry.size.width / 2,
            y: geometry.size.height / 2
        )
        .zIndex(101)
    }
}
