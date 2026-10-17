import SwiftUI
import WeatherKit

struct WeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme
    let attribution: WeatherAttribution
    
    var body: some View {
        Link(destination: attribution.legalPageURL) {
            AsyncImage(url: markURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                EmptyView()
            }
            .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .opacity(0.25)
        .accessibilityLabel("Weather data provided by Apple Weather")
    }
    
    private var markURL: URL {
        colorScheme == .dark
        ? attribution.combinedMarkDarkURL
        : attribution.combinedMarkLightURL
    }
}
