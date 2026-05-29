import SwiftUI

// 1. Custom Button Style to enforce perfect Capsule focus outlines on macOS
struct CapsuleButtonStyle: ButtonStyle {
    let isSelected: Bool
    let colorScheme: ColorScheme
    let tintColor: Color
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(
                isSelected ? tintColor : (colorScheme == .dark ? .white.opacity(0.10) : .black.opacity(0.10)),
                in: Capsule()
            )
            .opacity(configuration.isPressed ? 0.8 : 1.0)
#if os(macOS)
            .contentShape(.focusEffect, Capsule())
#endif
            .contentShape(Capsule())
    }
}

struct HourPickerSheet: View {
    @Binding var selectedHours: Set<Int>
    @AppStorage("rainThresholdPercent") private var rainThresholdPercent: Double = 5
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    @FocusState private var focusedHour: Int?
    
    @State private var rawSliderValue: Double = 5.0
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    @AppStorage("AppleAccentColor", store: UserDefaults(suiteName: "kCFPreferencesAnyApplication"))
    private var appleAccentColor: Int?
    
    private var tintColor: Color {
#if os(macOS)
        if appleAccentColor == nil {
            return .indigo
        } else {
            return .accentColor
        }
#else
        return .indigo
#endif
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<24, id: \.self) { (hour: Int) in
                            let isSelected = selectedHours.contains(hour)
                            Button {
                                focusedHour = hour
                                
                                if isSelected {
                                    selectedHours.remove(hour)
                                } else {
                                    selectedHours.insert(hour)
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .opacity(isSelected ? 1 : 0.75)
                                    Text(label(for: hour))
                                        .padding(.trailing, 4)
                                        .minimumScaleFactor(1.0)
                                        .frame(maxWidth: .infinity)
                                }
                                .foregroundColor(isSelected ? (colorScheme == .dark ? .black : .white) : .primary)
                                .opacity(isSelected ? 1 : 0.5)
                            }
                            .buttonStyle(CapsuleButtonStyle(isSelected: isSelected, colorScheme: colorScheme, tintColor: tintColor))
                            .focused($focusedHour, equals: hour)
                        }
                    }
                    .padding()
                }
                
                Divider()
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Rain threshold")
                        Spacer()
                        Text("\(Int(rawSliderValue))%")
                            .foregroundStyle(.secondary)
                    }
                    Slider(value: $rawSliderValue, in: 0.0...100.0)
                        .onChange(of: rawSliderValue) { _, newValue in
                            rainThresholdPercent = newValue.rounded()
                        }
                }
                .padding()
            }
            .navigationTitle("Select Hours")
            .tint(tintColor)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .tint(tintColor)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(selectedHours.count == 24 ? "Deselect All" : "Select All") {
                        if selectedHours.count == 24 {
                            selectedHours.removeAll()
                        } else {
                            selectedHours = Set(0...23)
                        }
                    }
                }
            }
        }
        .onAppear {
            rawSliderValue = rainThresholdPercent
            
            DispatchQueue.main.async {
                if let firstSelected = (0..<24).first(where: { selectedHours.contains($0) }) {
                    focusedHour = firstSelected
                } else {
                    focusedHour = 0
                }
            }
        }
    }
    
    private func label(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date)
    }
}
