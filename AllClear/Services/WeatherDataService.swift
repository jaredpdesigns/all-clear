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
    
    func refresh(using locationService: LocationService) async {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        
        let location: CLLocation
        do {
            location = try await locationService.requestCurrentLocation()
        } catch {
            guard let savedLocation = locationService.location else {
                errorMessage = locationService.errorMessage ?? error.localizedDescription
                return
            }
            location = savedLocation
        }
        
        locationService.errorMessage = nil
        Task { await locationService.updateLocationName(for: location) }
        
        do {
            attribution = try await service.attribution
            let calendar = Calendar.current
            let startDate = calendar.startOfDay(for: .now)
            guard let endDate = calendar.date(byAdding: .day, value: 2, to: startDate) else {
                errorMessage = "Unable to determine the forecast date range."
                return
            }
            
            let (currentWeather, dailyForecast, hourlyForecast) = try await service.weather(
                for: location,
                including: .current,
                .daily,
                .hourly(startDate: startDate, endDate: endDate)
            )
            self.currentWeather = currentWeather
            self.dailyForecast = Array(dailyForecast.prefix(2))
            self.hourlyForecast = Array(hourlyForecast)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
