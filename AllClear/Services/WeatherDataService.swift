import CoreLocation
import WeatherKit

@Observable
final class WeatherDataService {
    var currentWeather: CurrentWeather?
    var dailyForecast: [DayWeather] = []
    var hourlyForecast: [HourWeather] = []
    var attribution: WeatherAttribution?
    var isLoading = false
    var errorMessage: String?
    
    private let service = WeatherKit.WeatherService.shared
    
    func dayForecast(for day: ForecastDay) -> DayWeather? {
        let calendar = Calendar.current
        return switch day {
        case .today:
            dailyForecast.first { calendar.isDateInToday($0.date) }
                ?? dailyForecast.first
        case .tomorrow:
            dailyForecast.first { calendar.isDateInTomorrow($0.date) }
                ?? dailyForecast.dropFirst().first
        }
    }

    func fetchWeather(for location: CLLocation) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let weather = try await service.weather(for: location)
            currentWeather = weather.currentWeather
            dailyForecast = Array(weather.dailyForecast.prefix(2))
            hourlyForecast = Array(weather.hourlyForecast.prefix(48))
            attribution = try await service.attribution
        } catch {
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}
