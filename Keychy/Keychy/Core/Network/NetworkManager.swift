//
//  NetworkManager.swift
//  Keychy
//
//  Created by 길지훈 on 12/24/25.
//

import Foundation
import Network
import SwiftUI

@Observable
final class NetworkManager {
    static let shared = NetworkManager()
    
    /// 네트워크 상태 저장 변수
    var isConnected: Bool = false
    
    /// NWPathMonitor 인스턴스
    private let monitor = NWPathMonitor()
    
    /// 네트워크 모니터링 작업 큐
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    /// 외부 생성 방지 (싱글톤)
    private init() {}

    // MARK: - Methods
    /// 네트워크 상태 모니터링 시작, 실시간 상태 변화 감지
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = (path.status == .satisfied)

            Task { @MainActor in
                // 이전 연결 상태 저장
                let wasConnected = self?.isConnected ?? true
                self?.isConnected = connected

                // 연결 → 끊김 감지 시 토스트 표시
                if wasConnected && !connected {
                    ToastManager.shared.show()
                }

                print("[Network] 상태 변경: \(connected ? "온라인" : "오프라인")")
            }
        }
        monitor.start(queue: self.queue)
    }
    
    /// 네트워크 모니터링 종료
    /// - Note: 싱글톤이므로 일반적으로 호출될진 모르겠다.  테스트 또는 명시적 제어를 위해 일단 구현.
    func stopMonitoring() {
        monitor.cancel()
    }
    
}
