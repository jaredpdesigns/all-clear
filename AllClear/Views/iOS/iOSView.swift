#if os(iOS)
import SwiftUI
import WeatherKit

struct iOSView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherDataService.self) private var weatherService
    
    @State private var selectedHours = SharedSettings.selectedHours()
    @AppStorage(SharedSettings.filterModeKey, store: SharedSettings.defaults)
    private var filterMode: HourFilterMode = .selectedHours
    @State private var showingHourPicker = false
    @State private var selectedTab: ForecastDay = .today
    
    private var hasCustomSelection: Bool {
        selectedHours.count < 24
    }
    
    private var isRequestingLocation: Bool {
        (locationService.location == nil && locationService.isRequestingLocation && locationService.errorMessage == nil)
        || locationService.location != nil
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
                .background(Color(.systemBackground))
        }
        .onAppear {
            if selectedHours.count == 24 {
                filterMode = .allHours
            }
        }
        .onChange(of: selectedHours) { _, newValue in
            SharedSettings.saveSelectedHours(newValue)
            filterMode = newValue.count == 24 ? .allHours : .selectedHours
        }
        .onChange(of: filterMode) { _, newValue in
            SharedSettings.saveFilterMode(newValue)
        }
    }
    
    @ViewBuilder
    private func dayContent(for day: ForecastDay) -> some View {
        if weatherService.isLoading {
            WeatherLoadingView(attribution: weatherService.attribution)
        } else if let error = weatherService.errorMessage ?? locationService.errorMessage {
            WeatherErrorView(error: error) {
                Task { await weatherService.refresh(using: locationService) }
            }
        } else if weatherService.currentWeather == nil {
            if isRequestingLocation {
                WeatherLoadingView(attribution: weatherService.attribution)
            } else {
                LocationRequestView {
                    Task { await weatherService.refresh(using: locationService) }
                }
            }
        } else if let forecast = weatherService.dayForecast(for: day) {
            ScrollView {
                PrecipitationView(
                    currentWeather: day == .today ? weatherService.currentWeather : nil,
                    dayForecast: forecast,
                    hours: filteredHours(for: day),
                    date: day.date,
                    location: locationService.location,
                    locationName: locationService.locationName
                )
            }
            .refreshable {
                await weatherService.refresh(using: locationService)
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
                Picker(selection: $filterMode) {
                    Label {
                        Text("Selected Hours")
                    } icon: {
                        Image(systemName: "clock.badge.checkmark")
                            .foregroundStyle(.secondary)
                    }
                    .tag(HourFilterMode.selectedHours)
                    
                    Label {
                        Text("All Hours")
                    } icon: {
                        Image(systemName: "list.bullet")
                            .foregroundStyle(.secondary)
                    }
                    .tag(HourFilterMode.allHours)
                } label: {
                    EmptyView()
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
