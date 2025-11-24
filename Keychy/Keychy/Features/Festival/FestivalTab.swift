//
//  FestivalTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalTab: View {
    @Bindable var router: NavigationRouter<FestivalRoute>
    @State private var showCaseViewModel = Showcase25BoardViewModel()
    
    var body: some View {
        NavigationStack(path: $router.path) {
            FestivalView(router: router)
                .navigationDestination(for: FestivalRoute.self) { route in
                    switch route {
                    case .showcase25Board:
                        Showcase25BoardView(router: router)
                        
                    case .festivalKeyringDetailView(let keyring):
                        FestivalKeyringDetailView(router: router, viewModel: showCaseViewModel, keyring: keyring)
                        
                    case .coinCharge:
                        CoinChargeView(router: router)
                    }
                }
        }
    }
}
