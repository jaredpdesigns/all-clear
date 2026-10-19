import SwiftUI
import WeatherKit

struct RainForecastHourData: Identifiable {
    let date: Date
    let symbolName: String
    let temperature: Measurement<UnitTemperature>
    let windSpeed: Measurement<UnitSpeed>
    let precipitationChance: Double
    
    var id: Date { date }
    
    init(
        date: Date,
        symbolName: String,
        temperature: Measurement<UnitTemperature>,
        windSpeed: Measurement<UnitSpeed>,
        precipitationChance: Double
    ) {
        self.date = date
        self.symbolName = symbolName
        self.temperature = temperature
        self.windSpeed = windSpeed
        self.precipitationChance = precipitationChance
    }
    
    init(hour: HourWeather) {
        date = hour.date
        symbolName = hour.symbolName
        temperature = hour.temperature
        windSpeed = hour.wind.speed
        precipitationChance = hour.precipitationChance
    }
}

struct RainForecastHourRow: View {
    @Environment(\.locale) private var locale
    let hour: RainForecastHourData
    let rainThresholdPercent: Double
    
    private var hourFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = locale
        
        let uses24HourClock = DateFormatter.dateFormat(
            fromTemplate: "j",
            options: 0,
            locale: locale
        )?.contains("a") == false
        
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
        .measurement(
            width: .abbreviated,
            usage: .asProvided,
            numberFormatStyle: .number.precision(.fractionLength(0))
        )
        .locale(locale)
    }
    
    private var windSpeed: Measurement<UnitSpeed> {
        let preferredUnit: UnitSpeed = locale.measurementSystem == .metric
        ? .kilometersPerHour
        : .milesPerHour
        return hour.windSpeed.converted(to: preferredUnit)
    }
    
    private var isRaining: Bool {
        hour.precipitationChance >= rainThresholdPercent / 100
    }
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: isRaining ? "\(hour.symbolName).fill" : hour.symbolName)
                    .font(.headline)
                    .frame(width: 20)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isRaining ? Color("TextColor") : Color.primary)
                    .accessibilityHidden(true)
                
                Text(hour.date, formatter: hourFormatter)
                    .frame(width: 60, alignment: .leading)
                
                Text(hour.temperature.formatted(temperatureFormat))
                
                Label {
                    Text(windSpeed.formatted(windSpeedFormat))
                        .lineLimit(1)
                } icon: {
                    Image(systemName: "wind")
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .monospacedDigit()
            Spacer()
            
            Label {
                Text("\(Int(hour.precipitationChance * 100))%")
            } icon: {
                Image(systemName: isRaining ? "drop.fill" : "drop")
                    .foregroundStyle(isRaining ? Color("TextColor") : Color.secondary)
                    .accessibilityHidden(true)
            }
            .monospacedDigit()
            .frame(width: 64, alignment: .leading)
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
        .background(isRaining ? Color("AccentColor") : .clear)
        .foregroundStyle(isRaining ? Color("TextColor") : Color.primary)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }
    
    private var accessibilitySummary: Text {
        let time = hour.date.formatted(date: .omitted, time: .shortened)
        let temperature = hour.temperature.formatted(temperatureFormat)
        let wind = windSpeed.formatted(windSpeedFormat)
        let chance = Int(hour.precipitationChance * 100)
        let rainStatus = isRaining ? ", meets the rain threshold" : ""
        return Text("\(time), \(temperature), wind \(wind), precipitation chance \(chance) percent\(rainStatus)")
    }
}
