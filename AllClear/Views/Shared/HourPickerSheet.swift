import SwiftUI

struct HourPickerSheet: View {
    @Binding var selectedHours: Set<Int>
    @AppStorage("rainThresholdPercent") private var rainThresholdPercent: Double = 5
    @Environment(\.dismiss) private var dismiss

    @FocusState private var focusedHour: Int?

    @State private var rawSliderValue: Double = 5.0

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(0..<24, id: \.self) { (hour: Int) in
                            let isSelected = selectedHours.contains(hour)
                            let symbolName = isSelected ? "checkmark.circle.fill" : "circle.fill"
                            Button {
                                focusedHour = hour

                                if isSelected {
                                    selectedHours.remove(hour)
                                } else {
                                    selectedHours.insert(hour)
                                }
                            } label: {
                                HStack(spacing: 2) {
                                    Image(systemName: symbolName)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 20, height: 20)
                                        .foregroundStyle(isSelected ? Color("TextColor") : .white)
                                    Text(label(for: hour))
                                        .padding(.trailing, 4)
                                        .minimumScaleFactor(1.0)
                                        .frame(maxWidth: .infinity)
                                        .foregroundStyle(isSelected ? Color("TextColor") : .secondary)
                                        .strikethrough(isSelected ? false : true)
                                }
                            }
#if os(macOS)
                            .padding(8)
#else
                            .padding(4)
#endif
                            .background(isSelected ? Color("AccentColor") : Color("SecondaryBackground"), in: Capsule())
                            .focused($focusedHour, equals: hour)
                            .buttonStyle(.plain)
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
            .tint(Color("AccentColor"))
            .navigationTitle("Select Hours")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .foregroundStyle(Color("TextColor"))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color("AccentColor"))
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
