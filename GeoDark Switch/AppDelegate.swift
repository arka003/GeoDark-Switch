import Cocoa
import CoreLocation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    private var statusItem: NSStatusItem!
    private var window: NSWindow?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create status bar item using the SYSTEM status bar (not a new instance)
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        if let button = statusItem.button {
            // Use either a named image from your assets
            if let itemImage = NSImage(named: "StatusBarIcon") {
                itemImage.isTemplate = true  // Important for proper appearance in dark/light mode
                button.image = itemImage
            } else {
                // Fallback to a system symbol if image is missing
                button.image = NSImage(systemSymbolName: "sun.max.fill", accessibilityDescription: nil)
            }
            button.imageScaling = .scaleProportionallyUpOrDown
        }
        
        // Create the menu
        setupMenus()
        
        // Store reference to main window
        window = NSApplication.shared.windows.first
        
        // Load saved location if available
        if let latitude = UserDefaults.standard.object(forKey: "latitude") as? Double,
           let longitude = UserDefaults.standard.object(forKey: "longitude") as? Double {
            
            let location = CLLocation(latitude: latitude, longitude: longitude)
            // Access the ViewController
            if let viewController = window?.contentViewController as? ViewController {
                viewController.restoreLocation(location: location)
            }
        }
    }
    
    func setupMenus() {
        let menu = NSMenu()
        
        menu.addItem(NSMenuItem(title: "Show Window", action: #selector(showWindow(_:)), keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp(_:)), keyEquivalent: "q"))
        
        statusItem.menu = menu
    }
    
    @objc func showWindow(_ sender: NSMenuItem) {
        // Make app active
        NSApplication.shared.activate(ignoringOtherApps: true)
        
        // Show and bring window to front
        if let window = window {
            window.makeKeyAndOrderFront(nil)
        } else {
            // If window was closed, create a new one
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            let windowController = storyboard.instantiateController(withIdentifier: "MainWindowController") as! NSWindowController
            windowController.showWindow(nil)
            window = windowController.window
        }
    }
    
    @objc func quitApp(_ sender: NSMenuItem) {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ application: NSApplication) -> Bool {
        // Return false to keep the app running when window is closed
        return false
    }
}
