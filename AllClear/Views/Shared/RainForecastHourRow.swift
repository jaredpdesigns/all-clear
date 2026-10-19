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
    @Environment(\.colorScheme) private var colorScheme
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
    
    private var rainForeground: Color {
        colorScheme == .dark ? .black : .white
    }
    
    private var rainBackground: Color {
        colorScheme == .dark ? .white : .black
    }
    
    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: isRaining ? "\(hour.symbolName).fill" : hour.symbolName)
                    .font(.headline)
                    .frame(width: 20)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isRaining ? rainForeground : Color.primary)
                
                Text(hour.date, formatter: hourFormatter)
                    .frame(width: 40, alignment: .trailing)
                
                Text(hour.temperature.formatted(temperatureFormat))
                
                Label {
                    Text(windSpeed.formatted(windSpeedFormat))
                } icon: {
                    Image(systemName: "wind")
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .monospacedDigit()
            Spacer()
            
            Label {
                Text("\(Int(hour.precipitationChance * 100))%")
            } icon: {
                Image(systemName: isRaining ? "drop.fill" : "drop")
                    .foregroundStyle(isRaining ? rainForeground : Color.secondary)
            }
            .monospacedDigit()
            .frame(width: 64, alignment: .leading)
        }
        .frame(height: 44)
        .padding(.horizontal, 8)
        .background(isRaining ? rainBackground : .clear)
        .foregroundStyle(isRaining ? rainForeground : Color.primary)
    }
}
