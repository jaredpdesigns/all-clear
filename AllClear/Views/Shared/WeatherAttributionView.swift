import SwiftUI
import WeatherKit

struct WeatherAttributionView: View {
    let attribution: WeatherAttribution
    
    var body: some View {
        Link(destination: attribution.legalPageURL) {
            AsyncImage(url: attribution.combinedMarkLightURL) { image in
                image
                    .resizable()
                    .scaledToFit()
            } placeholder: {
                EmptyView()
            }
            .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .opacity(0.25)
    }
}
