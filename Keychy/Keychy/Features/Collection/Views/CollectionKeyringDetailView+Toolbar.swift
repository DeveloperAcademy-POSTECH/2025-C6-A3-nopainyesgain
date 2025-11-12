//
//  CollectionKeyringDetailView+Toolbar.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

// MARK: - 툴바
extension CollectionKeyringDetailView {
    var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                isSheetPresented = false
                router.pop()
            } label: {
                Image("BackIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            .opacity(showUIForCapture ? 1 : 0)
        }
    }

    var menuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                Image("MenuIcon")
                    .resizable()
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
                    .background(
                        GeometryReader { geometry in
                            Color.clear.preference(
                                key: MenuButtonPreferenceKey.self,
                                value: geometry.frame(in: .global)
                            )
                        }
                    )
            }
            .opacity(showUIForCapture ? 1 : 0)
        }
    }
}
