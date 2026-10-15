import CoreLocation
import SwiftUI
import WeatherKit
import WidgetKit

private let appGroupIdentifier = "group.com.jaredpdesigns.AllClear"
private let selectedHoursKey = "selectedHours"
private let filterModeKey = "filterMode"
struct RainForecastEntry: TimelineEntry {
    let date: Date
    let hours: [RainForecastHourData]
    let isUsingSelectedHours: Bool
    let rainThresholdPercent: Double
    let errorMessage: String?
    
    var averageChance: Double? {
        guard !hours.isEmpty else { return nil }
        return hours.map(\.precipitationChance).reduce(0, +) / Double(hours.count)
    }
}

struct RainForecastProvider: TimelineProvider {
    func placeholder(in context: Context) -> RainForecastEntry {
        RainForecastEntry(
            date: .now,
            hours: Array(0..<8).compactMap { (offset: Int) -> RainForecastHourData? in
                guard let date = Calendar.current.date(byAdding: .hour, value: offset, to: .now) else {
                    return nil
                }
                return RainForecastHourData(
                    date: date,
                    symbolName: "cloud.rain",
                    temperature: Measurement(value: 70, unit: UnitTemperature.fahrenheit),
                    windSpeed: Measurement(value: 5, unit: UnitSpeed.milesPerHour),
                    precipitationChance: 0.25
                )
            },
            isUsingSelectedHours: true,
            rainThresholdPercent: 5,
            errorMessage: nil
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (RainForecastEntry) -> Void) {
        Task {
            completion(await makeEntry())
        }
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<RainForecastEntry>) -> Void) {
        Task {
            let entry = await makeEntry()
            let nextRefresh = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now.addingTimeInterval(3600)
            completion(Timeline(entries: [entry], policy: .after(nextRefresh)))
        }
    }
    
    private func makeEntry() async -> RainForecastEntry {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier),
              let locationData = defaults.data(forKey: "savedLocation") else {
            return RainForecastEntry(
                date: .now,
                hours: [],
                isUsingSelectedHours: false,
                rainThresholdPercent: 5,
                errorMessage: "Open All Clear to set your location."
            )
        }
        
        do {
            let savedLocation = try JSONDecoder().decode(SharedSavedLocation.self, from: locationData)
            let location = CLLocation(
                latitude: savedLocation.latitude,
                longitude: savedLocation.longitude
            )
            let forecast = try await WeatherService.shared.weather(for: location, including: .hourly)
            let now = Date.now
            let endDate = Calendar.current.date(byAdding: .hour, value: 24, to: now) ?? now
            let upcomingHours = forecast.filter { $0.date >= now && $0.date < endDate }
            let selectedHours = Self.selectedHours(from: defaults)
            let filterMode = defaults.string(forKey: filterModeKey) ?? "Selected Hours"
            let rainThresholdPercent = defaults.object(forKey: "rainThresholdPercent") as? Double ?? 5
            let isUsingSelectedHours = filterMode != "All Hours" && selectedHours.count < 24
            let displayHours: [HourWeather]
            
            if isUsingSelectedHours {
                displayHours = upcomingHours.filter {
                    selectedHours.contains(Calendar.current.component(.hour, from: $0.date))
                }
            } else {
                displayHours = upcomingHours
            }
            
            return RainForecastEntry(
                date: now,
                hours: displayHours.map {
                    RainForecastHourData(hour: $0)
                },
                isUsingSelectedHours: isUsingSelectedHours,
                rainThresholdPercent: rainThresholdPercent,
                errorMessage: nil
            )
        } catch {
            return RainForecastEntry(
                date: .now,
                hours: [],
                isUsingSelectedHours: false,
                rainThresholdPercent: 5,
                errorMessage: error.localizedDescription
            )
        }
    }
    
    private static func selectedHours(from defaults: UserDefaults) -> Set<Int> {
        guard let data = defaults.data(forKey: selectedHoursKey),
              let hours = try? JSONDecoder().decode(Set<Int>.self, from: data) else {
            return Set(0...23)
        }
        return hours
    }
}

private struct SharedSavedLocation: Decodable {
    let latitude: Double
    let longitude: Double
    let name: String?
}

@main
struct AllClearWidgets: WidgetBundle {
    var body: some Widget {
        RainForecastWidget()
    }
}

struct RainForecastWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "AllClearRainForecast", provider: RainForecastProvider()) { entry in
            RainForecastView(entry: entry)
        }
        .configurationDisplayName("Rain Forecast")
        .description("See the chance of rain during your selected hours.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .systemExtraLarge])
    }
}

private struct RainForecastView: View {
    @Environment(\.widgetFamily) private var family
    @Environment(\.colorScheme) private var colorScheme
    let entry: RainForecastEntry
    
    var body: some View {
        Group {
            if (entry.errorMessage != nil) {
                ContentUnavailableView("Forecast Unavailable", systemImage: "cloud", description: Text("Please refresh your location"))
            } else if entry.hours.isEmpty {
                ContentUnavailableView(
                    "No Selected Hours",
                    systemImage: "clock",
                    description: Text("Choose forecast hours in All Clear.")
                )
            } else {
                switch family {
                case .systemSmall:
                    smallForecast
                case .systemMedium:
                    mediumForecast
                case .systemLarge, .systemExtraLarge:
                    largeForecast
                default:
                    smallForecast
                }
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }
    
    private var smallForecast: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Average Rain")
                .font(.headline)
            Text(hourRange)
                .font(.caption)
                .foregroundStyle(.secondary)
            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "cloud.rain")
                    .font(.headline)
                    .symbolRenderingMode(.hierarchical)
                Text(entry.averageChance ?? 0, format: .percent.precision(.fractionLength(0)))
                    .font(.system(size: 42, weight: .semibold))
                    .monospacedDigit()
            }
            Spacer()
        }.frame(maxWidth: .infinity)
    }
    
    private var mediumForecast: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Chance of Rain")
                .font(.headline.weight(.semibold))
            HStack(alignment: .center, spacing: 4) {
                ForEach(entry.hours.prefix(4)) { hour in
                    hourColumn(hour)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }
    
    private var largeForecast: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Chance of Rain")
                .font(.headline.weight(.semibold))
            VStack(spacing: 0) {
                ForEach(Array(entry.hours.prefix(6).enumerated()), id: \.element.id) { index, hour in
                    RainForecastHourRow(
                        hour: hour,
                        rainThresholdPercent: entry.rainThresholdPercent,
                        compact: true
                    )
                    .font(.footnote)
                    if index < min(entry.hours.count, 6) - 1 {
                        Divider()
                    }
                }
            }
            Spacer()
        }
    }
    
    private var hourRange: String {
        guard let firstHour = entry.hours.first,
              let lastHour = entry.hours.last,
              let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: lastHour.date) else {
            return ""
        }
        let formatter = DateIntervalFormatter()
        formatter.locale = Locale.current
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: firstHour.date, to: endDate)
    }
    
    private func hourColumn(_ hour: RainForecastHourData) -> some View {
        let isRaining = hour.precipitationChance >= entry.rainThresholdPercent / 100
        let rainForeground: Color = colorScheme == .dark ? .black : .white
        let rainBackground: Color = colorScheme == .dark ? .white : .black
        
        return VStack(spacing: 4) {
            Text(hour.date, format: .dateTime.hour())
                .font(.caption)
                .foregroundStyle(isRaining ? rainForeground : Color.secondary)
            Image(systemName: hour.symbolName)
                .symbolRenderingMode(.hierarchical)
                .foregroundStyle(isRaining ? rainForeground : Color.primary)
            Text(hour.temperature.formatted(
                .measurement(
                    width: .abbreviated,
                    usage: .weather,
                    numberFormatStyle: .number.precision(.fractionLength(0))
                )
            ))
            .font(.caption)
            .monospacedDigit()
            Text(hour.precipitationChance, format: .percent.precision(.fractionLength(0)))
                .font(.title3.weight(.semibold))
                .monospacedDigit()
        }
        .padding(8)
        .frame(maxWidth: .infinity)
        .background(isRaining ? rainBackground : .clear)
        .foregroundStyle(isRaining ? rainForeground : Color.primary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
