//
//  CollectionKeyringDetailView+Toolbar.swift
//  Keychy
//
//  Created by Jini on 11/10/25.
//

import SwiftUI

// MARK: - 툴바
extension CollectionKeyringDetailView {
    var customNavigationBar: some View {
        CustomNavigationBar {
            // Leading (왼쪽) - 뒤로가기 버튼
            BackToolbarButton {
                isSheetPresented = false
                router.pop()
            }
            .opacity(showUIForCapture ? 1 : 0)
        } center: {
            // Center (중앙)
            Text(showUIForCapture ? keyring.name : "")
                .foregroundStyle(.gray600)
        } trailing: {
            // Trailing (오른쪽) - 다음/구매 버튼
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    showMenu.toggle()
                }
            }) {
                Image("MenuIcon")
                    .resizable()
                    .frame(width: 34, height: 34)
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
            .frame(width: 44, height: 44)
            .glassEffect(.regular.interactive(), in: .circle)
            .opacity(showUIForCapture ? 1 : 0)
        }
    }
}
