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
        HStack(spacing: 12) {
            Text(hour.date, format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                .frame(width: 48, alignment: .trailing)
                .monospacedDigit()
            
            Image(systemName: hour.symbolName)
                .frame(width: 32, height: 32)
                .imageScale(.large)
                .symbolRenderingMode(.hierarchical)
            
            Text(hour.temperature.formatted(.measurement(width: .narrow, numberFormatStyle: .number.precision(.fractionLength(0)))))
                .frame(width: 32)
                .monospacedDigit()
            
            Spacer()
            
            Text("\(Int(hour.precipitationChance * 100))%")
                .monospacedDigit()
                .fontWeight(.bold)
        }
        .frame(height: 44)
    }
}
