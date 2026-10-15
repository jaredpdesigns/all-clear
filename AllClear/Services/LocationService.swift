import MapKit

@Observable
final class LocationService: NSObject {
    var location: CLLocation?
    var locationName: String?
    var authorizationStatus: CLAuthorizationStatus = .notDetermined
    var errorMessage: String?
    var isRequestingLocation = false
    
    private let manager = CLLocationManager()
    private var locationRetryCount = 0
    private let maxLocationRetries = 2
    private var locationRequestContinuation: CheckedContinuation<CLLocation, Error>?
    private var locationNameCoordinate: CLLocation?
    private static let savedLocationKey = "savedLocation"
    private let maximumLocationAge: TimeInterval = 15 * 60
    private let maximumHorizontalAccuracy: CLLocationAccuracy = 10_000
    
    private enum LocationRequestError: LocalizedError {
        case accessDenied
        case invalidLocation
        case unavailable
        case requestInProgress
        
        var errorDescription: String? {
            switch self {
            case .accessDenied:
                "Location access denied. Please enable it in Settings."
            case .invalidLocation:
                "A reliable location is not available yet. Please try again."
            case .unavailable:
                "Current location is temporarily unavailable. Please try again."
            case .requestInProgress:
                "A location request is already in progress."
            }
        }
    }
    
    private struct SavedLocation: Codable {
        let latitude: CLLocationDegrees
        let longitude: CLLocationDegrees
        let horizontalAccuracy: CLLocationAccuracy
        let timestamp: Date
        let name: String?
        
        init(location: CLLocation, name: String?) {
            latitude = location.coordinate.latitude
            longitude = location.coordinate.longitude
            horizontalAccuracy = location.horizontalAccuracy
            timestamp = location.timestamp
            self.name = name
        }
        
        var clLocation: CLLocation {
            CLLocation(
                coordinate: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                altitude: 0,
                horizontalAccuracy: horizontalAccuracy,
                verticalAccuracy: -1,
                timestamp: timestamp
            )
        }
    }
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
        authorizationStatus = manager.authorizationStatus
        if let savedLocation = Self.loadSavedLocation() {
            location = savedLocation.clLocation
            locationName = savedLocation.name
            locationNameCoordinate = savedLocation.name == nil ? nil : savedLocation.clLocation
        }
    }
    
    func requestCurrentLocation() async throws -> CLLocation {
        guard locationRequestContinuation == nil else {
            throw LocationRequestError.requestInProgress
        }
        
        errorMessage = nil
        isRequestingLocation = true
        locationRetryCount = 0
        return try await withCheckedThrowingContinuation { continuation in
            locationRequestContinuation = continuation
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
                finishLocationRequest(with: .failure(LocationRequestError.accessDenied))
            @unknown default:
                finishLocationRequest(with: .failure(LocationRequestError.accessDenied))
            }
        }
    }
    
    func updateLocationName(for location: CLLocation) async {
        if locationName != nil,
           let locationNameCoordinate,
           locationNameCoordinate.distance(from: location) < 1_000 {
            return
        }
        
        do {
            guard let request = MKReverseGeocodingRequest(location: location) else { return }
            let mapItems = try await request.mapItems
            guard self.location?.distance(from: location) ?? 0 < 1 else { return }
            
            guard let mapItem = mapItems.first,
                  let name = mapItem.addressRepresentations?.cityName
                    ?? mapItem.name
                    ?? mapItem.addressRepresentations?.regionName
                    else {
                return
            }
            
            locationName = name
            locationNameCoordinate = location
            saveLocation(location)
        } catch {
            // Keep the saved name if reverse geocoding is temporarily unavailable.
        }
    }
    
    private func finishLocationRequest(with result: Result<CLLocation, Error>) {
        isRequestingLocation = false
        
        switch result {
        case .success(let location):
            if let locationNameCoordinate,
               locationNameCoordinate.distance(from: location) >= 1_000 {
                locationName = nil
                self.locationNameCoordinate = nil
            }
            self.location = location
            errorMessage = nil
            saveLocation(location)
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
        
        let continuation = locationRequestContinuation
        locationRequestContinuation = nil
        continuation?.resume(with: result)
    }
    
    private func isAcceptable(_ location: CLLocation) -> Bool {
        let age = Date().timeIntervalSince(location.timestamp)
        return CLLocationCoordinate2DIsValid(location.coordinate)
        && location.horizontalAccuracy >= 0
        && location.horizontalAccuracy <= maximumHorizontalAccuracy
        && age >= -60
        && age <= maximumLocationAge
    }
    
    private func saveLocation(_ location: CLLocation) {
        let savedLocation = SavedLocation(location: location, name: locationName)
        guard let data = try? JSONEncoder().encode(savedLocation) else {
            return
        }
        UserDefaults.standard.set(data, forKey: Self.savedLocationKey)
        SharedSettings.saveLocationData(data)
    }
    
    private static func loadSavedLocation() -> SavedLocation? {
        guard let data = UserDefaults.standard.data(forKey: savedLocationKey),
              let savedLocation = try? JSONDecoder().decode(SavedLocation.self, from: data)
                else {
            return nil
        }
        
        let coordinate = CLLocationCoordinate2D(
            latitude: savedLocation.latitude,
            longitude: savedLocation.longitude
        )
        guard CLLocationCoordinate2DIsValid(coordinate), savedLocation.horizontalAccuracy >= 0 else {
            return nil
        }
        return savedLocation
    }
}

extension LocationService: CLLocationManagerDelegate {
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        let newLocation = locations.last
        Task { @MainActor in
            guard let newLocation, self.isAcceptable(newLocation) else {
                self.finishLocationRequest(with: .failure(LocationRequestError.invalidLocation))
                return
            }
            self.locationRetryCount = 0
            self.finishLocationRequest(with: .success(newLocation))
        }
    }
    
    nonisolated func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        let message = error.localizedDescription
        let isLocationUnknown = (error as? CLError)?.code == .locationUnknown
        Task { @MainActor in
            if isLocationUnknown && self.locationRetryCount < self.maxLocationRetries {
                self.locationRetryCount += 1
                self.isRequestingLocation = true
                self.manager.requestLocation()
                return
            }
            let failure: Error = isLocationUnknown
            ? LocationRequestError.unavailable
            : NSError(domain: "LocationService", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
            self.finishLocationRequest(with: .failure(failure))
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
                guard self.locationRequestContinuation != nil else { return }
                self.manager.requestLocation()
            } else if status == .denied || status == .restricted {
                self.finishLocationRequest(with: .failure(LocationRequestError.accessDenied))
            }
        }
    }
}
