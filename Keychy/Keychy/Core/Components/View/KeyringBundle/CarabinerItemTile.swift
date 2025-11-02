//
//  CarabinerSelectItemTile.swift
//  Keychy
//
//  Created by 김서현 on 10/29/25.
//

import SwiftUI

struct CarabinerItemTile: View {
    var isSelected: Bool
    var carabiner: Carabiner
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            Image(carabiner.carabinerImage[0])
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .padding(10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.1))
                )
                .overlay(
                    isSelected ?
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.black100.opacity(0.15)) : nil
                )
            Image(.cherries)
                .resizable()
                .scaledToFit()
                .frame(width: 32, height: 32)
                .padding(.top, 7)
                .padding(.leading, 10)
        }
    }
}

#Preview {
    CarabinerItemTile(
        isSelected: true,
        carabiner: Carabiner(
            id: "PreviewCarabiner",
            carabinerName: "카라비너",
            carabinerImage: ["ddochi"],
            description: "des",
            maxKeyringCount: 1,
            tags: ["tags"],
            price: 1,
            downloadCount: 1,
            useCount: 1,
            createdAt: Date(),
            keyringXPosition: [0.5],
            keyringYPosition: [0.3]
        )
    )
}
