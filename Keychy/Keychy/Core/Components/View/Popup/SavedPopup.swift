//
//  ImageSavePopup.swift
//  Keychy
//
//  Created by Jini on 11/9/25.
//

import SwiftUI

struct SavedPopup: View {
    @Binding var isPresented: Bool
    let message: String
    
    var body: some View {
        VStack(spacing: 15) {
            Image(.imageSave)
                .resizable()
                .frame(width: 161, height: 102)
                .padding(.top, 20)
            
            Text(message)
                .typography(.suit17SB)
                .frame(maxWidth: .infinity)
                .padding(.bottom, 12)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: 34))
        .frame(width: 300, height: 214)
        .transition(.scale.combined(with: .opacity))
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    isPresented = false
                }
            }
        }
    }
}
