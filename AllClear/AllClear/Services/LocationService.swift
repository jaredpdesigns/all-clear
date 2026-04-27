import CoreLocation

@Observable
final class LocationService: NSObject {
    var location: CLLocation?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?
    
    private let manager = CLLocationManager()
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    func requestLocation() {
        errorMessage = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            #if os(macOS)
            manager.requestAlwaysAuthorization()
            #else
            manager.requestWhenInUseAuthorization()
            #endif
        case .authorizedAlways:
            manager.requestLocation()
        #if !os(macOS)
        case .authorizedWhenInUse:
            manager.requestLocation()
        #endif
        case .denied, .restricted:
            errorMessage = "Location access denied. Please enable it in Settings."
        @unknown default:
            break
        }
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let newLocation = locations.first
        Task { @MainActor in
            self.location = newLocation
        }
    }
    
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        let message = error.localizedDescription
        Task { @MainActor in
            self.errorMessage = message
        }
    }
    
    nonisolated func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            #if os(macOS)
            let isAuthorized = status == .authorizedAlways
            #else
            let isAuthorized = status == .authorizedWhenInUse || status == .authorizedAlways
            #endif
            if isAuthorized {
                self.manager.requestLocation()
            }
        }
    }
}
