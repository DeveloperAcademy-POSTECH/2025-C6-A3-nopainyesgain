//
//  KeyringBundleItem.swift
//  KeytschPrototype
//
//  Created by 김서현 on 10/25/25.
//

// 뭉치 보관함 그리드에 들어가는 각각의 아이템 컴포넌트입니다
import SwiftUI

struct KeyringBundleItem: View {
    let bundle: KeyringBundle
    
    var body: some View {
        VStack(spacing: 5) {
            ZStack(alignment: .top) {
                //TODO: 실제 뭉치 씬으로 변경 필요
                Image(.ddochi)
                    .resizable()
                    .scaledToFit()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.2))
                    )
                if bundle.isMain {
                    UnevenRoundedRectangle(topLeadingRadius: 10, topTrailingRadius: 10)
                        .fill(.pink100.opacity(0.7))
                        .overlay(
                            Text("대표")
                                .typography(.suit13M)
                                .foregroundStyle(.white100)
                        )
                        .frame(height: 26)
                        .frame(maxWidth: .infinity)
                    
                }
            }
            
            HStack {
                Text(bundle.name)
                    .typography(.suit15SB25)
                    .foregroundStyle(.black100)
                Spacer()
            }
            HStack {
                Text("걸린 키링")
                    .typography(.suit12M)
                    .foregroundStyle(.gray500)
                Spacer()
                Text("\(bundle.keyrings.count) / \(bundle.maxKeyrings) 개")
                    .typography(.suit12M)
                    .foregroundStyle(.main500)
            }
        }
        
    }
}
