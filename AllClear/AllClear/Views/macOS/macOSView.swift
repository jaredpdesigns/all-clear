import SwiftUI
import WeatherKit

struct macOSView: View {
    @Environment(LocationService.self) private var locationService
    @Environment(WeatherDataService.self) private var weatherService
    
    @State private var selectedDay: ForecastDay = .today
    @State private var selectedHours: Set<Int> = {
        if let data = UserDefaults.standard.data(forKey: "selectedHours"),
           let hours = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return hours
        }
        return Set(0...23)
    }()
    @AppStorage("filterMode") private var filterMode: HourFilterMode = .selectedHours
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
                    locationService.requestLocation()
                }
            } else if weatherService.currentWeather == nil {
                if isRequestingLocation {
                    WeatherLoadingView(attribution: weatherService.attribution)
                } else {
                    LocationRequestView {
                        locationService.requestLocation()
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
                    .padding()
                    
                    ScrollView {
                        PrecipitationView(
                            currentWeather: selectedDay == .today ? weatherService.currentWeather : nil,
                            dayForecast: forecast,
                            hours: filteredHours,
                            date: selectedDay.date,
                            location: locationService.location
                        )
                        .frame(maxWidth: 600)
                    }
                    .frame(maxWidth: .infinity)
                }
            } else {
                ForecastUnavailableView(day: selectedDay)
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button {
                    showingHourPicker = true
                } label: {
                    Image(systemName: "clock")
                        .symbolRenderingMode(.hierarchical)
                }
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button {
                        filterMode = .selectedHours
                    } label: {
                        if filterMode == .selectedHours {
                            Label("Selected Hours", systemImage: "checkmark")
                        } else {
                            Text("Selected Hours")
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
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: "selectedHours")
            }
            filterMode = newValue.count == 24 ? .allHours : .selectedHours
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
