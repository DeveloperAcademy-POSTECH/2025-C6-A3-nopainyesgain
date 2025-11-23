//
//  Showcase25BoardView.swift
//  Keychy
//
//  Created by rundo on 11/23/25.
//

import SwiftUI

struct Showcase25BoardView: View {

    @Bindable var router: NavigationRouter<FestivalRoute>

    var body: some View {
        ZStack(alignment: .top) {
            Color.white
                .ignoresSafeArea()

            VStack {
                Text("Showcase 2025 Board")
                    .typography(.notosans17M)
                    .padding(.top, 100)

                Spacer()
            }

            customNavigationBar
        }
        .ignoresSafeArea()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden()
    }

    // MARK: - Custom Navigation Bar

    private var customNavigationBar: some View {
        CustomNavigationBar {
            BackToolbarButton {
                router.pop()
            }
        } center: {
            Text("쇼케이스 2025")
                .typography(.notosans17M)
        } trailing: {
            Spacer()
                .frame(width: 44, height: 44)
        }
    }
}
