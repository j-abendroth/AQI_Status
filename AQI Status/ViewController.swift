//
//  ViewController.swift
//  AQI Status
//
//  Main view controller class
//  Shows the AQI data from the selected service
//  Provides the user with different options for what data to fetch and display
//

import Cocoa
import Foundation

class ViewController: NSViewController, NSTextFieldDelegate {
    // setup the timer that will auto update the AQI data every 15 minutes
    weak var timer: Timer?
    
    // set up zip code text box and triggered function for when a new zip code is entered
    @IBOutlet weak var zipCodeTextField: NSTextField!
    func controlTextDidEndEditing(_ obj: Notification) {
        // once the zip code is entered, update the stored zip code value
        AQIData.shared.zipCode = zipCodeTextField.stringValue
        // signal we're fetching new data from PA
        AQIData.shared.fetchNewData = true
        AQIData.shared.updateData()
        print("Changed text = \(zipCodeTextField.stringValue)\n")
    }
    @IBOutlet weak var AQINum: NSTextField!
    @IBOutlet weak var AQIDescription: NSTextField!
    @IBOutlet weak var cityName: NSTextField!
    @IBOutlet weak var dateString: NSTextField!
    
    // set up the distance filter slider and trigger a recalc of the PM data when the slider is moved
    @IBOutlet weak var distanceFilterSlider: NSSlider!
    @IBAction func sliderValueChanged(_ sender: Any) {
        // update new filtering distance and recalculate AQI once slider has changed
        AQIData.shared.filterDistance = distanceFilterSlider.doubleValue
        // signal we're just refreshing the cached PM data
        AQIData.shared.fetchNewData = false
        DispatchQueue.global(qos: .userInitiated).async {
            AQIData.shared.calcPM()
        }
    }
    // if new conversion menu option is selected, recalc the PM data
    @IBOutlet weak var conversionPopup: NSPopUpButton!
    @IBAction func conversionSelected(_ sender: Any) {
        let conversionSelected = conversionPopup.titleOfSelectedItem
        if conversionSelected == "None" {
            AQIData.shared.AQandU = false
            AQIData.shared.LRAPA = false
        }
        if conversionSelected == "AQandU" {
            AQIData.shared.AQandU = true
            AQIData.shared.LRAPA = false
        }
        if conversionSelected == "LRAPA" {
            AQIData.shared.AQandU = false
            AQIData.shared.LRAPA = true
        }
        
        // signal we're just refreshing the cached PM data
        AQIData.shared.fetchNewData = false
        DispatchQueue.global(qos: .userInitiated).async {
            AQIData.shared.calcPM()
        }
    }
    // if new data averaging length is selected, re updated all AQI data
    @IBOutlet weak var dataAveragePopup: NSPopUpButton!
    @IBAction func averageSelected(_ sender: Any) {
        let avgSelected = dataAveragePopup.titleOfSelectedItem
        if avgSelected == "Realtime" {
            AQIData.shared.avgSelection = "a0"
            AQIData.shared.pmNum = "pm_0,"
        }
        if avgSelected == "10 Minute Average" {
            AQIData.shared.avgSelection = "a10"
            AQIData.shared.pmNum = "pm_1,"
        }
        if avgSelected == "30 Minute Average" {
            AQIData.shared.avgSelection = "a30"
            AQIData.shared.pmNum = "pm_2,"
        }
        if avgSelected == "1 Hour Average" {
            AQIData.shared.avgSelection = "a60"
            AQIData.shared.pmNum = "pm_3,"
        }
        if avgSelected == "1 Day Average" {
            AQIData.shared.avgSelection = "a1140"
            AQIData.shared.pmNum = "pm_5,"
        }
        if avgSelected == "1 Week Average" {
            AQIData.shared.avgSelection = "a10080"
            AQIData.shared.pmNum = "pm_6,"
        }
        // signal we're fetching new data from PA
        AQIData.shared.fetchNewData = true
        AQIData.shared.updateData()
    }
    
    @IBAction func quitButton(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zipCodeTextField.delegate = self

        // set default zip code entry to Santa Cruz
        zipCodeTextField.stringValue = "95062"
        
        // setup notification observer for UI updates
        NotificationCenter.default.addObserver(self, selector: #selector(updateAQIView(_:)), name: .updateAQI, object: nil)
        
        // start the timer to update the AQI every 30 minutes
        startTimer()
        // get initial update of the app
        AQIData.shared.fetchNewData = true
        AQIData.shared.updateData()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    static func newViewController() -> ViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("ViewController")
          
        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? ViewController else {
            fatalError("Unable to instantiate ViewController in Main.storyboard")
        }
        return viewcontroller
    }
    
    // set up the timer to fetch new data every 15 minutes
    // 15 min = 900 sec
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 900.0, repeats: true) { [weak self] timer in
            // signal we're fetching new data from PA
            AQIData.shared.fetchNewData = true
            AQIData.shared.updateData()
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
    }
    
    // the function triggered from notification center to update the UI
    @objc func updateAQIView(_ notification: Notification) {
        // accessing app delegate has to be run on main queue
        // update the UI fields when trigged by a notification
        // pull the data from the AQI Data class
        DispatchQueue.main.async {
            let appDelegate = NSApp.delegate as? AppDelegate
            guard let AQI = AQIData.shared.AQI, let button = appDelegate?.statusItem.button else {
                return
            }
            
            let AQIString = "\(AQI)"
            self.AQINum.stringValue = AQIString
            self.AQIDescription.stringValue = AQIData.shared.getAQIDescription()
            self.cityName.stringValue = AQIData.shared.cityName + ", " + AQIData.shared.stateName
            // only want to update the date string when we've fetched new data from purple air
            if AQIData.shared.fetchNewData {
                self.dateString.objectValue = Date()
            }
            button.title = AQIString
        }
    }
    
    
    
    // remove timer and notification center observer
    deinit {
        NotificationCenter.default.removeObserver(self, name: .updateAQI, object: nil)
        stopTimer()
    }
}

// create extension for notification center for our own notification name
extension Notification.Name {
    static let updateAQI = Notification.Name(rawValue: "updateAQI")
}
