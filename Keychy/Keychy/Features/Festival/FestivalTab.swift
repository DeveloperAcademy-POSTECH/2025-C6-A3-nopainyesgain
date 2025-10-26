//
//  FestivalTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalTab: View {
    @Bindable var router: NavigationRouter<FestivalRoute>
    
    var body: some View {
        NavigationStack(path: $router.path) {
            FestivalView()
                .navigationDestination(for: FestivalRoute.self) { route in
                    // 나중에 추가
                }
        }
    }
}
