//
//  KeyringSelectableCell.swift
//  Keychy
//
//  Created by 김서현 on 01/13/25.
//

import SwiftUI

struct KeyringSelectableCell: View {
    let keyring: Keyring
    let isSelectedHere: Bool
    let isSelectedElsewhere: Bool
    let width: CGFloat
    let height: CGFloat
    let onTapSelect: () -> Void
    let onTapDeselect: () -> Void

    var body: some View {
        Button {
            if isSelectedHere {
                onTapDeselect()
            } else if !isSelectedElsewhere {
                onTapSelect()
            } else {
                // 중복 선택 방지: 아무 것도 하지 않음
            }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                VStack(spacing: 10) {
                    ZStack {
                        CollectionCellView(keyring: keyring)
                            .frame(width: width, height: height)
                            .cornerRadius(10)

                        // 선택 테두리
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(isSelectedHere ? .mainOpacity80 : .clear, lineWidth: 1.8)
                            .frame(width: width, height: height)

                        // 다른 위치에 장착된 경우 dim
                        if isSelectedElsewhere {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(Color.black50)
                                .frame(width: width, height: height)
                        }
                    }

                    Text(keyring.name)
                        .typography(isSelectedHere ? .notosans14SB : .notosans14M)
                        .foregroundStyle(isSelectedHere ? .main500 : .black100)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                // “장착 중” 배지
                if isSelectedElsewhere || isSelectedHere {
                    VStack {
                        HStack {
                            Spacer()
                            Text("장착 중")
                                .foregroundStyle(.white100)
                                .typography(.suit13M)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(.mainOpacity80)
                                )
                        }
                        Spacer()
                    }
                    .padding(.top, 5)
                    .padding(.trailing, 5)
                }
            }
        }
        .disabled(keyring.status == .packaged || keyring.status == .published || isSelectedElsewhere)
        .opacity(1.0)
    }
}
