//
//  FestivalView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalView: View {
    @Bindable var router: NavigationRouter<FestivalRoute>
    
    var body: some View {
        ZStack {
            Image(.festivalTrailer)
                .resizable()
                .scaledToFill()
                .offset(y: getBottomPadding(34) == 34 ? 50 : 0)
                .frame(width: screenWidth, height: screenHeight)
            
            Button {
                router.push(.festivalDetailView)
            } label: {
                Text("이동하기")
                    .foregroundStyle(.white)
                    .padding(30)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue)
                    )
            }
        }
    }
}
