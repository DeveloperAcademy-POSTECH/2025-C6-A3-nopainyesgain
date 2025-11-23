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
            FestivalView(
                router: router
            )
                .navigationDestination(for: FestivalRoute.self) { route in
                    switch route {
                    case .festivalDetailView:
                        FestivalDetailView(router: router)
                    }
                    
                }
        }
    }
}
