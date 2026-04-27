import SwiftUI
import WeatherKit

struct WeatherAttributionView: View {
    let attribution: WeatherAttribution
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Link(destination: attribution.legalPageURL) {
            AsyncImage(url: colorScheme == .dark
                       ? attribution.combinedMarkDarkURL
                       : attribution.combinedMarkLightURL
            ) { image in
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
