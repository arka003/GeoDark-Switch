import Cocoa
import CoreLocation

class ViewController: NSViewController, CLLocationManagerDelegate {
    
    @IBOutlet weak var locationTextField: NSTextField!
    
    private let locationManager = CLLocationManager()
    private var timer: Timer?
    private var sunrise: Date?
    private var sunset: Date?
    private var currentLocation: CLLocation?
    private let geocoder = CLGeocoder()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.delegate = self
        
        // Set up timer to check every minute
        timer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(checkTimeAndUpdateAppearance), userInfo: nil, repeats: true)
    }
    
    @IBAction func applyButtonClicked(_ sender: NSButton) {
        guard !locationTextField.stringValue.isEmpty else {
            showAlert(message: "Please enter a location")
            return
        }
        
        // Define locationString here so it's in scope for the entire method
           let locationString = locationTextField.stringValue
           
           // Geocode the location string to get coordinates
           geocoder.geocodeAddressString(locationString) { [weak self] (placemarks, error) in
               guard let self = self else { return }
               
               if let error = error {
                   DispatchQueue.main.async {
                       self.showAlert(message: "Error finding location: \(error.localizedDescription)")
                   }
                   return
               }
               
               guard let placemark = placemarks?.first,
                     let location = placemark.location else {
                   DispatchQueue.main.async {
                       self.showAlert(message: "Location not found")
                   }
                   return
               }
               
               self.currentLocation = location
               self.calculateSunriseSunset()
               
               DispatchQueue.main.async {
                   self.showAlert(message: "Location set to: \(placemark.name ?? locationString)")
                   self.checkTimeAndUpdateAppearance()
               }
           }
       }
    
    private func calculateSunriseSunset() {
        guard let location = currentLocation else { return }
        
        // Using solar calculation for demo purposes
        // In a real app, you might want to use a more accurate API
        let solar = Solar(coordinate: location.coordinate)
        sunrise = solar.sunrise
        sunset = solar.sunset
        
        UserDefaults.standard.set(location.coordinate.latitude, forKey: "latitude")
        UserDefaults.standard.set(location.coordinate.longitude, forKey: "longitude")
    }
    
    private func runAppleScript(_ script: String) {
        let task = Process()
        task.launchPath = "/usr/bin/osascript"
        task.arguments = ["-e", script]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
        } catch {
            print("Error executing AppleScript: \(error)")
        }
    }
    
    @objc private func checkTimeAndUpdateAppearance() {
        guard let sunrise = sunrise, let sunset = sunset else { return }
        
        let now = Date()
        let isDayTime = now > sunrise && now < sunset
        
        // Set system appearance based on time of day
        if isDayTime {
            // Set to Light Mode
            runAppleScript("tell app \"System Events\" to tell appearance preferences to set dark mode to false")
        } else {
            // Set to Dark Mode
            runAppleScript("tell app \"System Events\" to tell appearance preferences to set dark mode to true")
        }
        
        print("Time check: \(now)")
        print("Sunrise: \(sunrise), Sunset: \(sunset)")
        print("Setting appearance to: \(isDayTime ? "Light Mode" : "Dark Mode")")
    }
    
    private func showAlert(message: String) {
        let alert = NSAlert()
        alert.messageText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    func restoreLocation(location: CLLocation) {
        self.currentLocation = location
        calculateSunriseSunset()
        checkTimeAndUpdateAppearance()
    }

}

// Solar calculation helper struct
struct Solar {
    let coordinate: CLLocationCoordinate2D
    
    var sunrise: Date? {
        return calculateSunriseSunset(isSunrise: true)
    }
    
    var sunset: Date? {
        return calculateSunriseSunset(isSunrise: false)
    }
    
    private func calculateSunriseSunset(isSunrise: Bool) -> Date? {
        // Basic calculation of sunrise/sunset
        // This is a simplified version - in a real app you'd use a more accurate algorithm
        
        let calendar = Calendar.current
        let now = Date()
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        
        // Set approximate time for sunrise/sunset based on location
        components.hour = isSunrise ? 6 : 18
        components.minute = 0
        components.second = 0
        
        // Adjust based on latitude (rough approximation)
        let latitudeAdjustment = abs(coordinate.latitude) / 90.0 * 3 // Max 3 hour adjustment
        
        if isSunrise {
            components.hour = components.hour! - Int(latitudeAdjustment)
        } else {
            components.hour = components.hour! + Int(latitudeAdjustment)
        }
        
        return calendar.date(from: components)
    }
}
