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

    private var temperatureFormat: Measurement<UnitTemperature>.FormatStyle {
        .measurement(width: .abbreviated, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0)))
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
            Text(date, format: .dateTime.weekday(.wide).month(.wide).day())
                .foregroundStyle(.secondary)

            HStack(spacing: 32) {
                Text(
                    (currentWeather?.temperature ?? dayForecast.highTemperature)
                        .formatted(temperatureFormat)
                )
                .font(.system(size: 48))
            }

            HStack(spacing: 16) {
                Text("H: \(dayForecast.highTemperature.formatted(temperatureFormat))")
                Text("L: \(dayForecast.lowTemperature.formatted(temperatureFormat))")
            }
            .foregroundStyle(.secondary)
        }
    }

    private var hourlySection: some View {
        VStack(alignment: .leading, spacing: 0) {
            if hours.isEmpty {
                HourSelectionEmptyView()
                    .frame(maxWidth: .infinity, minHeight: 240)
            } else {
                ForEach(Array(hours.enumerated()), id: \.element.date) { index, hour in
                    HourRow(hour: hour)

                    if index < hours.count - 1 {
                        Divider()
                    }
                }
            }
        }
    }

}

private struct HourRow: View {
    let hour: HourWeather

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: hour.precipitationChance > 0  ? "\(hour.symbolName).fill" : hour.symbolName)
                .font(.title2)
                .frame(width: 24)
                .symbolRenderingMode(.hierarchical)

            HStack(spacing: 4) {
                Text(hour.date, format: Date.VerbatimFormatStyle(
                    format: "\(hour: .defaultDigits(clock: .twelveHour, hourCycle: .oneBased))",
                    timeZone: .current,
                    calendar: .current
                ))
                .monospacedDigit()

                Text(Calendar.current.component(.hour, from: hour.date) < 12 ? "AM" : "PM")
                    .font(.body.smallCaps())
            }
            .frame(width: 48, alignment: .trailing)

            Text("\(hour.temperature.formatted(.measurement( numberFormatStyle: .number.precision(.fractionLength(0)))))")
                .monospacedDigit()

            Label {
                Text("\(hour.wind.speed.converted(to: .milesPerHour).value, specifier: "%.0f") mph")
            } icon: {
                Image(systemName: "wind")
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()

            Spacer()

            Label {
                Text("\(Int(hour.precipitationChance * 100))%")
            } icon: {
                Image(systemName: hour.precipitationChance > 0 ? "drop.fill" : "drop")
                    .foregroundStyle(.secondary)
            }
            .monospacedDigit()
            .frame(width: 72, alignment: .leading)
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
        .background(
            Color.yellow.opacity(hour.precipitationChance > 0 ? 0.10 : 0)
        )
    }
}
