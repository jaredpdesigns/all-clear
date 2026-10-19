import CoreLocation
import SwiftUI

struct ContentView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherDataService.self) private var weatherService
    
    var body: some View {
        platformView
            .task { await weatherService.refresh(using: locationService) }
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
