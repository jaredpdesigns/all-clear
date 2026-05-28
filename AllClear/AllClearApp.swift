import SwiftUI

@main
struct AllClearApp: App {
    @State private var locationService = LocationService()
    @State private var weatherDataService = WeatherDataService()
    
    var body: some Scene {
#if os(macOS)
        Window("All Clear", id: "main") {
            ContentView()
                .environment(locationService)
                .environment(weatherDataService)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)
#else
        WindowGroup {
            ContentView()
                .environment(locationService)
                .environment(weatherDataService)
        }
#endif
    }
}
