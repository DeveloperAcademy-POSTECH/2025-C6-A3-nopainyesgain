//
//  CurrentItemsCard.swift
//  Keychy
//
//  현재 보유 아이템을 표시하는 재사용 가능한 컴포넌트
//

import SwiftUI

struct CurrentItemsCard: View {
    @State private var userManager = UserManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            itemCard(
                image: "myCoin",
                title: "열쇠",
                count: "\(userManager.currentUser?.coin ?? 0)"
            )
            
            itemCard(
                image: "myKeyringCount",
                title: "내 보유 키링",
                count: "\(userManager.currentUser?.keyrings.count ?? 0)/\(userManager.currentUser?.maxKeyringCount ?? 100)"
            )
            
            itemCard(
                image: "myCopyPass",
                title: "복사권",
                count: "\(userManager.currentUser?.copyVoucher ?? 0)/10"
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 5)
        .padding(.bottom, 15)
        .background(.gray50)
        .cornerRadius(15)
    }
    
    private func itemCard(image: String, title: String, count: String) -> some View {
        VStack(spacing: 5) {
            Image(image)
                .padding(.vertical, 8)
                .padding(.horizontal, 35)
            
            Text(title)
                .typography(.suit12M)
                .foregroundStyle(.black100)
            
            Text(count)
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
    }
}

// MARK: - Preview
#Preview {
    CurrentItemsCard()
        .padding(.horizontal, 20)
}
