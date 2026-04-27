import SwiftUI
import WeatherKit

struct WeatherLoadingView: View {
    var attribution: WeatherAttribution?

    var body: some View {
        VStack {
            Spacer()
            ProgressView("Fetching weather…")
            Spacer()
            if let attribution {
                WeatherAttributionView(attribution: attribution)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
