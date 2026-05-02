import SwiftUI

struct HourPickerSheet: View {
    @Binding var selectedHours: Set<Int>
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) var colorScheme
    
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(0..<24, id: \.self) { hour in
                        let isSelected = selectedHours.contains(hour)
                        Button {
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
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.plain)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 4)
                        .background(
                            Capsule()
                                .fill(isSelected ? (colorScheme == .dark ? .white : .black) : (colorScheme == .dark ? .white.opacity(0.10) : .black.opacity(0.10)))
                        )
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
