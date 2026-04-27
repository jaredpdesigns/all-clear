#if os(iOS)
import SwiftUI
import WeatherKit

struct iOSView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherDataService.self) private var weatherService

    @State private var selectedHours: Set<Int> = {
        if let data = UserDefaults.standard.data(forKey: "selectedHours"),
           let hours = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return hours
        }
        return Set(0...23)
    }()
    @AppStorage("filterMode") private var filterMode: HourFilterMode = .selectedHours
    @State private var showingHourPicker = false
    @State private var selectedTab: ForecastDay = .today

    private var hasCustomSelection: Bool {
        selectedHours.count < 24
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Today", systemImage: "calendar", value: ForecastDay.today) {
                NavigationStack {
                    dayContent(for: .today)
                        .navigationTitle("Today")
                        .toolbar { toolbarItems }
                }
            }
            Tab("Tomorrow", systemImage: "calendar.badge.clock", value: ForecastDay.tomorrow) {
                NavigationStack {
                    dayContent(for: .tomorrow)
                        .navigationTitle("Tomorrow")
                        .toolbar { toolbarItems }
                }
            }
        }
        .sheet(isPresented: $showingHourPicker) {
            HourPickerSheet(selectedHours: $selectedHours)
                .presentationDetents([.medium, .large])
        }
        .onChange(of: selectedHours) { _, newValue in
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "selectedHours")
            }
            if newValue.count == 24 {
                filterMode = .allHours
            }
        }
        .tint(.primary)
    }

    @ViewBuilder
    private func dayContent(for day: ForecastDay) -> some View {
        if weatherService.isLoading {
            WeatherLoadingView(attribution: weatherService.attribution)
        } else if let error = weatherService.errorMessage ?? locationService.errorMessage {
            WeatherErrorView(error: error) {
                locationService.requestLocation()
            }
        } else if weatherService.currentWeather == nil {
            LocationRequestView {
                locationService.requestLocation()
            }
        } else if let forecast = weatherService.dayForecast(for: day) {
            ScrollView {
                PrecipitationView(
                    currentWeather: day == .today ? weatherService.currentWeather : nil,
                    dayForecast: forecast,
                    hours: filteredHours(for: day),
                    date: day.date,
                    location: locationService.location
                )
            }
        } else {
            ForecastUnavailableView(day: day)
        }
    }

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                showingHourPicker = true
            } label: {
                Image(systemName: "clock")
                    .symbolRenderingMode(.hierarchical)
            }
        }
        ToolbarItem(placement: .navigationBarTrailing) {
            Menu {
                if hasCustomSelection {
                    Button {
                        filterMode = .selectedHours
                    } label: {
                        if filterMode == .selectedHours {
                            Label("Selected Hours", systemImage: "checkmark")
                        } else {
                            Text("Selected Hours")
                        }
                    }
                }
                Button {
                    filterMode = .allHours
                } label: {
                    if filterMode == .allHours {
                        Label("All Hours", systemImage: "checkmark")
                    } else {
                        Text("All Hours")
                    }
                }
            } label: {
                Image(systemName: "line.3.horizontal.decrease")
            }
        }
    }

    private func filteredHours(for day: ForecastDay) -> [HourWeather] {
        let calendar = Calendar.current
        let dayHours: [HourWeather] = switch day {
        case .today:
            weatherService.hourlyForecast.filter { calendar.isDateInToday($0.date) }
        case .tomorrow:
            weatherService.hourlyForecast.filter { calendar.isDateInTomorrow($0.date) }
        }

        guard hasCustomSelection, filterMode == .selectedHours else {
            return dayHours
        }
        return dayHours.filter { hour in
            selectedHours.contains(calendar.component(.hour, from: hour.date))
        }
    }
}
#endif
