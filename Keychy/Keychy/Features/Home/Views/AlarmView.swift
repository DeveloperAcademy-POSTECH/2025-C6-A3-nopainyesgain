//
//  AlarmView.swift
//  Keychy
//
//  Created by rundo on 10/31/25.
//

import SwiftUI

struct AlarmView: View {
    
    @State private var isNotiEmpty: Bool = false
    @State private var isNotiOff: Bool = true
    @State private var isNotiOffShown: Bool = false
    
    var body: some View {
        ZStack {
            emptyImageView
            VStack(spacing: 0) {
                if isNotiOff {
                    pushNotiOffView
                }
                
                Spacer()
                   
            }
        }
        .padding(.top, 10)
        .navigationTitle("알림")
        .navigationBarTitleDisplayMode(.inline)
        
    }
    
}


extension AlarmView {
    private var emptyImageView: some View {
        VStack(alignment: .center, spacing: 0) {
            Image("EmptyViewIcon")
            Text("알림함이 비었어요.")
                .typography(.suit15R)
                .padding(15)
        }
    }
    
    private var pushNotiOffView: some View {
        HStack(alignment: .center) {
            /// 알람 아이콘
            Image("AlarmIconFill")
                .padding(.vertical, 3.5)
                .padding(.trailing, 12)

            /// 알림 off 텍스트
            VStack(alignment: .leading ,spacing: 8) {
                HStack {
                    Text("기기 알림이 꺼져있어요! 알림을 켜주세요.")
                        .typography(.suit15B25)
                        .foregroundStyle(.black100)
                    Spacer()
                    /// 알림 off 뷰 닫기 버튼
                    Button {
                        isNotiOffShown = false
                    } label: {
                        Image("dismiss_gray300")
                    }
                }
                Text("눌러서 알림 활성화 하기")
                    .typography(.suit13M)
                    .foregroundStyle(.gray400)
            }
        }
        .padding(.vertical, 18)
        .padding(.horizontal, 25)
        .frame(maxWidth: .infinity)
        
        .background(.gray50)
    }
}
