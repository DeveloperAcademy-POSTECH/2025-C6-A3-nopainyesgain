//
//  LocationManager.swift
//  Keychy
//
//  Created by seo on 11/25/25.
//

import CoreLocation
import SwiftUI

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    // 목표 위치와 활성화 반경(미터)
    var targetLocations: [TargetLocation] = []
    
    override init() {
        super.init()
        manager.delegate = self
        // 배터리 절약을 위해 정확도 낮춤 (100m 정도 오차)
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        // 50m 이상 이동했을 때만 업데이트
        manager.distanceFilter = 50
        // 백그라운드에서 위치 업데이트 일시 중지 (배터리 절약)
        manager.pausesLocationUpdatesAutomatically = true
        // 활동 유형 설정 (최적화에 도움)
        manager.activityType = .other
    }
    
    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }
    
    func startTracking() {
        manager.startUpdatingLocation()
    }
    
    func stopTracking() {
        manager.stopUpdatingLocation()
    }
    
    // 한 번만 위치 가져오기 (배터리 절약 극대화)
    func requestSingleLocation() {
        manager.requestLocation()
    }
    
    // 특정 위치가 활성화 범위 안에 있는지 확인
    func isLocationActive(_ target: TargetLocation) -> Bool {
        guard let currentLocation = currentLocation else { return false }
        let distance = currentLocation.distance(from: target.coordinate)
        return distance <= target.radius
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        
        switch authorizationStatus {
        case .notDetermined:
            print("📍 위치 권한: 아직 결정되지 않음")
        case .restricted:
            print("⚠️ 위치 권한: 제한됨 (자녀 보호 기능 등)")
        case .denied:
            print("❌ 위치 권한: 거부됨 - 설정에서 권한을 허용해주세요")
        case .authorizedWhenInUse:
            print("✅ 위치 권한: 앱 사용 중 허용됨")
            startTracking()
        case .authorizedAlways:
            print("✅ 위치 권한: 항상 허용됨")
            startTracking()
        @unknown default:
            print("⚠️ 위치 권한: 알 수 없는 상태")
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
        currentLocation = locations.last
        if let location = currentLocation {
            print("📍 위치 업데이트: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager,
                        didFailWithError error: Error) {
        let clError = error as? CLError
        switch clError?.code {
        case .denied:
            print("❌ 위치 오류: 권한이 거부되었습니다. 설정 > 개인정보보호 > 위치서비스에서 권한을 허용해주세요.")
        case .locationUnknown:
            print("⚠️ 위치 오류: 위치를 찾을 수 없습니다. 잠시 후 다시 시도됩니다.")
        case .network:
            print("⚠️ 위치 오류: 네트워크 문제로 위치를 가져올 수 없습니다.")
        default:
            print("❌ 위치 오류: \(error.localizedDescription)")
        }
    }
}

// 목표 위치 모델
struct TargetLocation: Identifiable {
    let id = UUID()
    let name: String
    let coordinate: CLLocation
    let radius: Double // 미터 단위
    
    init(name: String, latitude: Double, longitude: Double, radius: Double = 50) {
        self.name = name
        self.coordinate = CLLocation(latitude: latitude, longitude: longitude)
        self.radius = radius
    }
}
