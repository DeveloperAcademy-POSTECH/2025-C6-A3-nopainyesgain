//
//  CircleGlassButton.swift
//  Keychy
//
//  Created by Jini on 10/29/25.
//

import SwiftUI

struct CircleGlassButton: View {
    var imageName: String
    var action: () -> Void // 버튼 동작 액션
    
    var body: some View {
        Button(action: {
            action()
        }) {
            Image("\(imageName)")
                .resizable()
                .scaledToFit()
                .frame(width: 36, height: 36)
        }
        .frame(width: 44, height: 44)
        .buttonStyle(.plain)
        .glassEffect(.regular.interactive(), in: .circle)
    }
}

// MARK: - Preview
#Preview {
    CollectionView(router: NavigationRouter<CollectionRoute>(), collectionViewModel: CollectionViewModel())
}
