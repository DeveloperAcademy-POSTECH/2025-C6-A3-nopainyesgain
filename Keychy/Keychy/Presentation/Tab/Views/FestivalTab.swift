//
//  FestivalTab.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import SwiftUI

struct FestivalTab: View {
    @Bindable var router: NavigationRouter<FestivalRoute>
    @Bindable var workshopRouter: NavigationRouter<WorkshopRoute>
    @Bindable var showcaseVM: Showcase25BoardViewModel
    var onSwitchToWorkshop: ((WorkshopRoute) -> Void)? = nil
    
    var body: some View {
        NavigationStack(path: $router.path) {
            FestivalView(router: router)
                .navigationDestination(for: FestivalRoute.self) { route in
                    switch route {
                    case .showcase25BoardView:
                        Showcase25BoardView(
                            festivalRouter: router,
                            workshopRouter: workshopRouter,
                            viewModel: showcaseVM,
                            onNavigateToWorkshop: { route in
                                onSwitchToWorkshop?(route)
                            }
                        )
                        
                    case .festivalView:
                        FestivalView(router: router)
                    case .festivalKeyringDetailView(let keyring):
                        FestivalKeyringDetailView(
                            festivalRouter: router,
                            workshopRouter: workshopRouter,
                            viewModel: showcaseVM,
                            keyring: keyring
                        )
                    case .coinCharge:
                        CoinChargeView(router: router)
                    }
                }
        }
    }
}
