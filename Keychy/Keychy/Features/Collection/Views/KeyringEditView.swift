//
//  KeyringEditView.swift
//  Keychy
//
//  Created by Jini on 11/6/25.
//

import SwiftUI

struct KeyringEditView: View {
    @Bindable var router: NavigationRouter<CollectionRoute>
    
    let keyring: Keyring
    
    var body: some View {
        Text("수정 화면")
            .navigationTitle(keyring.name)
            .navigationBarBackButtonHidden(true)
            .toolbar(.hidden, for: .tabBar)
            .toolbar {
                backToolbarItem
                menuToolbarItem
            }
    }
}

// MARK: - 툴바
extension KeyringEditView {
    private var backToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Button {
                router.pop()
            } label: {
                Image(systemName: "chevron.left")
                    .foregroundColor(.primary)
            }
        }
    }
    
    private var menuToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button(action: {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    //
                }
            }) {
                Image(systemName: "ellipsis")
                    .foregroundColor(.primary)
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
        }
    }
}
