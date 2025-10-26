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
            //TODO: 실제 뭉치 씬으로 변경 필요
            Image(.ddochi)
                .resizable()
                .scaledToFit()
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.2))
                )
            
            HStack {
                bundle.isMain ? Image(systemName: "pin.fill") : nil
                Text(bundle.name)
                    .font(.system(size: 16, weight: .semibold))
                Spacer()
            }
            HStack {
                Text("걸린 키링")
                    .font(.system(size: 11, weight: .medium))
                Spacer()
                Text("\(bundle.keyrings.count) / \(bundle.maxKeyrings) 개")
                    .foregroundStyle(Color.blue)
                    .font(.system(size: 13, weight: .medium))
            }
        }
    }
}
