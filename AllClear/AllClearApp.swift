import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
struct AllClearApp: App {
#if os(macOS)
    @NSApplicationDelegateAdaptor private var appDelegate: MenuBarDelegate
#endif
    @State private var locationService = LocationService()
    @State private var weatherDataService = WeatherDataService()
    
    init() {
        SharedSettings.migrateLegacyPreferences()
    }
    
    var body: some Scene {
#if os(macOS)
        Window("All Clear", id: "main") {
            ContentView()
                .frame(minWidth: 400)
                .environment(locationService)
                .environment(weatherDataService)
        }
        .windowResizability(.contentSize)
        .defaultSize(width: 600, height: 500)
#else
        WindowGroup {
            ContentView()
                .environment(locationService)
                .environment(weatherDataService)
        }
#endif
    }
}

#if os(macOS)
private final class MenuBarDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        removeStandardMenus()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMainWindowChange),
            name: NSWindow.didBecomeMainNotification,
            object: nil
        )
    }

    @objc private func handleMainWindowChange() {
        removeStandardMenus()
    }

    private func removeStandardMenus() {
        DispatchQueue.main.async {
            guard let mainMenu = NSApplication.shared.mainMenu,
                  let appMenu = mainMenu.items.first,
                  mainMenu.items.count > 1 else {
                return
            }

            mainMenu.items.removeAll { $0 !== appMenu }
        }
    }
}
#endif
