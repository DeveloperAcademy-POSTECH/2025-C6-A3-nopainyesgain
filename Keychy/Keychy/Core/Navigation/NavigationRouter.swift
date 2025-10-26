//
//  NavigationRouter.swift
//  KeytschPrototype
//
//  Created by 길지훈 on 10/16/25.
//

import Foundation

@Observable
final class NavigationRouter<Route: Hashable> {
    var path: [Route] = []
    
    init() {}
    
    func push(_ route: Route) {
        path.append(route)
    }
    
    func pop() {
        _ = path.popLast()
    }
    
    func reset() {
        path.removeAll()
    }
}
