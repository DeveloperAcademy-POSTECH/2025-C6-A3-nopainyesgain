//
//  FestivalView.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalView: View {
    var body: some View {
        Image(.festivalTrailer)
            .resizable()
            .scaledToFill()
            .offset(y: getBottomPadding(34) == 34 ? 20 : 0)
            .frame(width: screenWidth, height: screenHeight)
    }
}
