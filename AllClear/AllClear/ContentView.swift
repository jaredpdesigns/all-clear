import CoreLocation
import SwiftUI

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherDataService.self) private var weatherService
    
    var body: some View {
        platformView
            .task { locationService.requestLocation() }
            .onChange(of: locationService.location) { _, newLocation in
                guard let location = newLocation else { return }
                Task { await weatherService.fetchWeather(for: location) }
            }
    }
    
    @ViewBuilder
    private var platformView: some View {
#if os(iOS)
        iOSView()
#elseif os(macOS)
        macOSView()
#endif
    }
}
