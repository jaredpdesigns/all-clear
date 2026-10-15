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
    @Environment(\.locale) private var locale
    @AppStorage("rainThresholdPercent", store: SharedSettings.defaults)
    private var rainThresholdPercent: Double = 5
    var currentWeather: CurrentWeather?
    let dayForecast: DayWeather
    let hours: [HourWeather]
    let date: Date
    let location: CLLocation?
    let locationName: String?
    
    private var temperatureFormat: Measurement<UnitTemperature>.FormatStyle {
        .measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))
        .locale(locale)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            conditionsSection
            VStack(spacing: 0) {
                Divider()
                hourlySection
            }
            
        }
        .padding()
    }
    
    private var conditionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let locationName {
                Label {
                    Text(locationName)
                } icon: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(.secondary)
                }
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .padding(4)
                .padding(.trailing, 6)
                .background(Capsule().fill(Color("SecondaryBackground")))
            }
            
            Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                .foregroundStyle(.secondary)
            
            HStack(spacing: 32) {
                Text(
                    (currentWeather?.temperature ?? dayForecast.highTemperature)
                        .formatted(temperatureFormat)
                )
                .font(.system(size: 48))
                .monospacedDigit()
            }
            
            HStack(spacing: 16) {
                Text("H: \(dayForecast.highTemperature.formatted(temperatureFormat))")
                Text("L: \(dayForecast.lowTemperature.formatted(temperatureFormat))")
            }
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }
    }
    
    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hours.isEmpty {
                HourSelectionEmptyView()
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                ForEach(Array(hours.enumerated()), id: \.element.date) { index, hour in
                    RainForecastHourRow(
                        hour: RainForecastHourData(hour: hour),
                        rainThresholdPercent: rainThresholdPercent
                    )
                    
                    if index < hours.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }
    
}
