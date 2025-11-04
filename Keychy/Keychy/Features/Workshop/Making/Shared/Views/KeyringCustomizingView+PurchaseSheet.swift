//
//  KeyringCustomizingView+PurchaseSheet.swift
//  Keychy
//
//  유료 아이템 구매 시트
//

import SwiftUI

// MARK: - Purchase Sheet
extension KeyringCustomizingView {
    var purchaseSheet: some View {
        VStack(spacing: 0) {
            
            /// 상단 닫기, 타이틀
            ZStack {
                // 타이틀 (중앙)
                Text("구매하기")
                    .typography(.suit15B25)
                    .foregroundStyle(.black100)

                // 닫기 버튼 (왼쪽)
                HStack {
                    dismissButton
                        .padding(.leading, 20)
                    Spacer()
                }
            }
            .padding(.top, 30)
            .padding(.bottom, 22)

            

            /// 장바구니 리스트 (스크롤 가능)
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(cartItems) { item in
                        purchaseItemRow(item: item)
                    }
                }
                .padding(.horizontal, 20)
            }
            .padding(.bottom, 20)

            Spacer()

            // 내 보유 포인트
            HStack(spacing: 4) {
                Text("내 보유 :")
                    .typography(.suit15M25)
                    .foregroundStyle(.black100)

                Text("\(UserManager.shared.currentUser?.coin ?? 0)")
                    .typography(.nanum16EB)
                    .foregroundStyle(.main500)
            }
            .padding(.bottom, 16)

            // 구매 버튼
            purchaseButton
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
        }
        .background(
            GeometryReader { geometry in
                Color.clear.preference(
                    key: PurchaseSheetHeightPreferenceKey.self,
                    value: geometry.size.height
                )
            }
        )
        .background(Color.white100)
        .presentationBackground(Color.white100)
        .onPreferenceChange(PurchaseSheetHeightPreferenceKey.self) { height in
            if height > 0 {
                purchaseSheetHeight = height
            }
        }
        .presentationDetents([.height(purchaseSheetHeight)])
    }
}

// MARK: - Components
extension KeyringCustomizingView {
    /// 닫기 버튼
    private var dismissButton: some View {
        Button {
            showPurchaseSheet = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 20))
                .foregroundStyle(.black100)
        }
    }

    /// 구매 아이템 Row
    private func purchaseItemRow(item: EffectItem) -> some View {
        HStack(spacing: 0) {
            // 아이콘 (유료 표시)
            Image("selected")
                .padding(.trailing, 6)

            // 아이템 이름
            Text(item.name)
                .typography(.suit17B)
                .foregroundStyle(.black100)
                .padding(.trailing, 3)

            // 타입 표시
            Text(item.type.rawValue)
                .typography(.suit14M)
                .foregroundStyle(.gray400)

            Spacer()

            // 가격
            Text("\(item.price)")
                .typography(.nanum16EB)
                .foregroundStyle(.main500)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(Color.gray50)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    /// 구매 버튼
    private var purchaseButton: some View {
        Button {
            Task {
                await handlePurchase()
            }
        } label: {
            HStack(spacing: 5) {
                Image("purchaseSheet")

                Text("\(totalCartPrice)")
                    .typography(.nanum18EB)

                Text("(\(cartItems.count)개)")
                    .typography(.suit17SB)
            }
            .foregroundStyle(.white100)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(.black80)
            .clipShape(RoundedRectangle(cornerRadius: 100))
        }
    }
}

// MARK: - PreferenceKey
struct PurchaseSheetHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 500
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
