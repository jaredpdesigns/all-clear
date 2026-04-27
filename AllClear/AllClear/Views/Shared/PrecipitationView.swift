import SwiftUI
import WeatherKit
import CoreLocation
import MapKit

enum ForecastDay: String, CaseIterable {
    case today = "Today"
    case tomorrow = "Tomorrow"

    var date: Date {
        switch self {
        case .today: Date()
        case .tomorrow: Calendar.current.date(byAdding: .day, value: 1, to: Date())!
        }
    }
}

struct PrecipitationView: View {
    var currentWeather: CurrentWeather?
    let dayForecast: DayWeather
    let hours: [HourWeather]
    let date: Date
    let location: CLLocation?

    @State private var cityName: String?

    private var temperatureFormat: Measurement<UnitTemperature>.FormatStyle {
        .measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            conditionsSection
            Divider()
            hourlySection
        }
        .padding()
        .task(id: location) {
            guard let location else { return }
            await fetchCityName(for: location)
        }
    }

    private func fetchCityName(for location: CLLocation) async {
        let searchRequest = MKLocalSearch.Request()
        searchRequest.region = MKCoordinateRegion(
            center: location.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        )
        searchRequest.resultTypes = .address

        let search = MKLocalSearch(request: searchRequest)
        do {
            let response = try await search.start()
            cityName = response.mapItems.first?.address?.locality
        } catch {
            cityName = nil
        }
    }

    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 16) {

                Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                    .foregroundStyle(.secondary)

                     if let cityName {
                Label(cityName, systemImage: "location.fill.circle")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            }

            HStack(spacing: 32) {
                Text(
                    (currentWeather?.temperature ?? dayForecast.highTemperature)
                        .formatted(temperatureFormat)
                )
                .font(.system(size: 48))

                Label {
                    if let currentWeather {
                        Text(currentWeather.condition.description.capitalized)
                    } else {
                        Text(dayForecast.condition.description.capitalized)
                    }
                } icon: {
                    Image(systemName: currentWeather?.symbolName ?? dayForecast.symbolName)
                        .imageScale(.large)
                        .symbolRenderingMode(.hierarchical)
                }
                .font(.title2)
            }

            HStack(spacing: 16) {
                Text("H: \(dayForecast.highTemperature.formatted(temperatureFormat))")
                Text("L: \(dayForecast.lowTemperature.formatted(temperatureFormat))")
            }
            .foregroundStyle(.secondary)
        }
    }

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(hours, id: \.date) { hour in
                HourRow(hour: hour)
            }
        }
    }

}

private struct HourRow: View {
    let hour: HourWeather

    var body: some View {
        HStack(spacing: 12) {
            Text(hour.date, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                .frame(width: 48, alignment: .trailing)
                .monospacedDigit()

            Image(systemName: hour.symbolName)
                .frame(width: 32)
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)

            Text(hour.temperature.formatted(.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(0)))))
                .frame(width: 32)
                .monospacedDigit()

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(.tertiary.opacity(0.25))
                        .frame(width: geo.size.width)

                    if hour.precipitationChance > 0 {
                        Capsule()
                            .fill(precipitationColor)
                            .frame(width: geo.size.width * hour.precipitationChance)
                    }
                }
            }
            .frame(height: 8)

            Text("\(Int(hour.precipitationChance * 100))%")
                .frame(width: 48, alignment: .trailing)
                .monospacedDigit()
        }
    }

    private var precipitationColor: Color {
        switch hour.precipitationChance {
        case 0..<0.2: .primary.opacity(0.4)
        case 0.2..<0.5: .primary.opacity(0.6)
        case 0.5..<0.8: .primary.opacity(0.8)
        default: .primary
        }
    }
}
