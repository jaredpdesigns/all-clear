import SwiftUI

struct HourPickerSheet: View {
    @Binding var selectedHours: Set<Int>
    @Environment(\.dismiss) private var dismiss

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<24, id: \.self) { hour in
                        let isSelected = selectedHours.contains(hour)
                        Button {
                            if isSelected {
                                selectedHours.remove(hour)
                            } else {
                                selectedHours.insert(hour)
                            }
                        } label: {
                            Text(label(for: hour))
                                .font(.subheadline.weight(isSelected ? .semibold : .regular))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(
                                    isSelected ? AnyShapeStyle(Color.accentColor) : AnyShapeStyle(.tertiary),
                                    in: RoundedRectangle(cornerRadius: 10)
                                )
                                .foregroundStyle(isSelected ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Select Hours")
            #if !os(macOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
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
    }

    private func label(for hour: Int) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h a"
        let date = Calendar.current.date(from: DateComponents(hour: hour))!
        return formatter.string(from: date)
    }
}
