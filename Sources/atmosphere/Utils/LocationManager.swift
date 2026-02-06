import CoreLocation
import Foundation

@MainActor
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let key = "lastKnownLocationName"
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var locationName: String?
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        permissionStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func requestLocation() {
#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorized || status == .authorizedWhenInUse {
            manager.requestLocation()
        } else {
            requestPermission()
        }
#else
        let status = manager.authorizationStatus
        if status == .authorizedAlways || status == .authorized {
            manager.requestLocation()
        } else {
            requestPermission()
        }
#endif
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus
    ) {
        Task { @MainActor in
#if os(iOS) || os(tvOS) || os(visionOS) || os(watchOS)
            if status == .authorizedAlways || status == .authorized || status == .authorizedWhenInUse {
                self.manager.requestLocation()
            }
#else
            if status == .authorizedAlways || status == .authorized {
                self.manager.requestLocation()
            }
#endif
            self.permissionStatus = status
        }
    }

    nonisolated func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            self.location = location
            self.fetchLocationName(for: location)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }

    private func fetchLocationName(for location: CLLocation) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, error in
            guard let self = self else { return }

            if let error = error {
                print("Reverse geocoding error: \(error.localizedDescription)")
                return
            }

            if let placemark = placemarks?.first {
                // Try to construct a meaningful name: "City, State" or "Points of Interest"
                var name = placemark.name ?? placemark.locality ?? "Unknown Location"

                if let locality = placemark.locality, name != locality {
                    name += ", \(locality)"
                }

                Task { @MainActor in
                    self.locationName = name
                }
            }
        }
    }
}

