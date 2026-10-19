import SwiftUI
import WeatherKit

struct macOSView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherDataService.self) private var weatherService
    
    @State private var selectedDay: ForecastDay = .today
    @State private var selectedHours = SharedSettings.selectedHours()
    @AppStorage(SharedSettings.filterModeKey, store: SharedSettings.defaults)
    private var filterMode: HourFilterMode = .selectedHours
    @State private var showingHourPicker = false
    
    private var hasCustomSelection: Bool {
        selectedHours.count < 24
    }
    
    private var isRequestingLocation: Bool {
        (locationService.location == nil && locationService.isRequestingLocation && locationService.errorMessage == nil)
        || locationService.location != nil
    }
    
    var body: some View {
        Group {
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
            } else if let forecast = weatherService.dayForecast(for: selectedDay) {
                VStack(spacing: 0) {
                    Picker("", selection: $selectedDay) {
                        ForEach(ForecastDay.allCases, id: \.self) { day in
                            Text(day.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .tint(.accentColor)
                    .padding()
                    
                    ScrollView {
                        PrecipitationView(
                            currentWeather: selectedDay == .today ? weatherService.currentWeather : nil,
                            dayForecast: forecast,
                            hours: filteredHours,
                            date: selectedDay.date,
                            location: locationService.location,
                            locationName: locationService.locationName,
                            attribution: weatherService.attribution
                        )
                        .frame(maxWidth: 600)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForecastUnavailableView(day: selectedDay)
            }
        }
#if os(macOS)
        .containerBackground(.regularMaterial, for: .window)
#endif
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingHourPicker = true
                } label: {
                    Image(systemName: "clock")
                        .symbolRenderingMode(.hierarchical)
                }
                .accessibilityLabel("Select forecast hours")
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Picker(selection: $filterMode) {
                        Label("Selected Hours", systemImage: "clock.badge.checkmark")
                            .tag(HourFilterMode.selectedHours)
                        Label("All Hours", systemImage: "list.bullet")
                            .tag(HourFilterMode.allHours)
                    } label: {
                        EmptyView()
                    }
                    .pickerStyle(.inline)
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .accessibilityLabel("Filter forecast hours")
            }
            ToolbarItem(placement: .automatic) {
                Button {
                    Task { await weatherService.refresh(using: locationService) }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .accessibilityLabel("Refresh weather")
                .disabled(weatherService.isLoading)
                .help("Refresh Weather")
                .keyboardShortcut("r", modifiers: .command)
            }
        }
        .sheet(isPresented: $showingHourPicker) {
            HourPickerSheet(selectedHours: $selectedHours)
                .frame(minWidth: 360, minHeight: 320)
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
    
    private var filteredHours: [HourWeather] {
        let calendar = Calendar.current
        let dayHours: [HourWeather] = switch selectedDay {
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
