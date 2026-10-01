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
    @Environment(\.locale) private var locale
    @AppStorage("rainThresholdPercent") private var rainThresholdPercent: Double = 5
    let hour: HourWeather
    
    private var uses24HourClock: Bool {
        let formatString = DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: .current
        ) ?? ""
        
        return !formatString.contains("a")
    }
    
    private var hourFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        
        let uses24HourClock =
        DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: locale
        )?
            .contains("a") == false
        
        if uses24HourClock {
            formatter.dateFormat = "HH:mm"
        } else {
            formatter.setLocalizedDateFormatFromTemplate("j")
        }
        
        return formatter
    }
    
    private var temperatureFormat: Measurement<UnitTemperature>.FormatStyle {
        .measurement(
            width: .abbreviated,
            usage: .weather,
            numberFormatStyle: .number.precision(.fractionLength(0))
        )
        .locale(locale)
    }
    
    private var windSpeedFormat: Measurement<UnitSpeed>.FormatStyle {
        Measurement<UnitSpeed>.FormatStyle
            .measurement(
                width: .abbreviated,
                usage: .asProvided,
                numberFormatStyle: .number.precision(.fractionLength(0))
            )
            .locale(locale)
    }
    
    private var windSpeed: Measurement<UnitSpeed> {
        let preferredUnit: UnitSpeed = locale.measurementSystem == .metric ? .kilometersPerHour : .milesPerHour
        return hour.wind.speed.converted(to: preferredUnit)
    }
    
    private var isRaining: Bool {
        hour.precipitationChance >= rainThresholdPercent / 100
    }
    
    var body: some View {
        HStack(spacing: 16) {
            HStack(spacing: 16) {
                Image(systemName: isRaining  ? "\(hour.symbolName).fill" : hour.symbolName)
                    .font(.title2)
                    .frame(width: 24)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isRaining ? Color("TextColor") : .primary)
                
                Text(hour.date, formatter: hourFormatter)
                    .monospacedDigit()
                    .frame(width: 48, alignment: .trailing)
                
                Text(hour.temperature.formatted(temperatureFormat))
                    .monospacedDigit()
                
                Label {
                    Text(windSpeed.formatted(windSpeedFormat))
                } icon: {
                    Image(systemName: "wind")
                        .foregroundStyle(.secondary)
                }
                .monospacedDigit()
            }.frame(maxWidth: .infinity, alignment: .leading)
            
            Label {
                Text("\(Int(hour.precipitationChance * 100))%")
            } icon: {
                Image(systemName: isRaining ? "drop.fill" : "drop")
                    .foregroundStyle(isRaining ? Color("TextColor") : .secondary)
            }
            .monospacedDigit()
            .frame(width: 72, alignment: .leading)
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
        .background(isRaining ? Color("AccentColor") : .clear)
        .foregroundStyle(isRaining ? Color("TextColor") : .primary)
    }
}
