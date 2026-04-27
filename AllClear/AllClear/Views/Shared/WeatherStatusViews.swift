import SwiftUI

struct WeatherErrorView: View {
    let error: String
    let onRetry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Unable to Load", systemImage: "exclamationmark.triangle")
        } description: {
            Text(error)
        } actions: {
            Button("Retry", action: onRetry)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LocationRequestView: View {
    let onRequestLocation: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Waiting for Location", systemImage: "location")
        } description: {
            Text("Grant location access to see precipitation data.")
        } actions: {
            Button("Request Location", action: onRequestLocation)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct ForecastUnavailableView: View {
    let day: ForecastDay

    var body: some View {
        ContentUnavailableView {
            Label("Forecast Unavailable", systemImage: "cloud.slash")
        } description: {
            Text("Unable to load the \(day.rawValue.lowercased()) forecast.")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
