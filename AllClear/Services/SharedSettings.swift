import Foundation
import OSLog
import WidgetKit

enum SharedSettings {
    static let appGroupIdentifier = "group.com.jaredpdesigns.AllClear"
    static let selectedHoursKey = "selectedHours"
    static let filterModeKey = "filterMode"
    
    private static let logger = Logger(
        subsystem: "com.jaredpdesigns.AllClear",
        category: "SharedSettings"
    )
    
    static var defaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }
    
    static func selectedHours() -> Set<Int> {
        if let data = defaults?.data(forKey: selectedHoursKey),
           let hours = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return hours
        }
        
        if let data = UserDefaults.standard.data(forKey: selectedHoursKey),
           let hours = try? JSONDecoder().decode(Set<Int>.self, from: data) {
            return hours
        }
        
        return Set(0...23)
    }
    
    static func saveSelectedHours(_ hours: Set<Int>) {
        do {
            let data = try JSONEncoder().encode(hours)
            guard let defaults else {
                logger.error("Unable to open the All Clear App Group preferences.")
                UserDefaults.standard.set(data, forKey: selectedHoursKey)
                return
            }
            defaults.set(data, forKey: selectedHoursKey)
            UserDefaults.standard.set(data, forKey: selectedHoursKey)
            reloadWidgets()
        } catch {
            logger.error("Unable to save selected forecast hours: \(error.localizedDescription)")
        }
    }
    
    static func saveFilterMode(_ mode: HourFilterMode) {
        guard let defaults else {
            logger.error("Unable to open the All Clear App Group preferences.")
            return
        }
        defaults.set(mode.rawValue, forKey: filterModeKey)
        reloadWidgets()
    }
    
    static func saveRainThreshold(_ value: Double) {
        guard let defaults else {
            logger.error("Unable to open the All Clear App Group preferences.")
            return
        }
        defaults.set(value, forKey: "rainThresholdPercent")
        UserDefaults.standard.set(value, forKey: "rainThresholdPercent")
        reloadWidgets()
    }
    
    static func saveLocationData(_ data: Data) {
        guard let defaults else {
            logger.error("Unable to open the All Clear App Group preferences.")
            return
        }
        defaults.set(data, forKey: "savedLocation")
        reloadWidgets()
    }
    
    private static func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    static func migrateLegacyPreferences() {
        guard let defaults else {
            logger.error("Unable to open the All Clear App Group preferences.")
            return
        }
        
        for key in [selectedHoursKey, filterModeKey, "rainThresholdPercent", "savedLocation"] {
            guard defaults.object(forKey: key) == nil,
                  let legacyValue = UserDefaults.standard.object(forKey: key) else {
                continue
            }
            defaults.set(legacyValue, forKey: key)
        }
    }
}
