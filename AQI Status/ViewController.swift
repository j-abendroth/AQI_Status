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
    
    @IBOutlet weak var zipCodeTextField: NSTextField!
    func controlTextDidEndEditing(_ obj: Notification) {
        // once the zip code is entered, update the stored zip code value
        AQIData.shared.zipCode = zipCodeTextField.stringValue
        AQIData.shared.updateData()
        print("Changed text = \(zipCodeTextField.stringValue)\n")
    }
    @IBOutlet weak var AQINum: NSTextField!
    @IBOutlet weak var AQIDescription: NSTextField!
    @IBOutlet weak var cityName: NSTextField!
    
    @IBOutlet weak var distanceFilterSlider: NSSlider!
    @IBAction func sliderValueChanged(_ sender: Any) {
        // update new filtering distance and recalculate AQI once slider has changed
        AQIData.shared.filterDistance = distanceFilterSlider.doubleValue
        AQIData.shared.calcPM()
    }
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
        
        AQIData.shared.calcPM()
    }
    
    @IBOutlet weak var dataAveragePopup: NSPopUpButton!
    @IBAction func averageSelected(_ sender: Any) {
    }
    
    
    @IBAction func quitButton(_ sender: Any) {
        NSApplication.shared.terminate(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zipCodeTextField.delegate = self

        // set default zip code entry to Santa Cruz
        zipCodeTextField.stringValue = "95062"
        
        // setup notification observer
        NotificationCenter.default.addObserver(self, selector: #selector(updateAQIView(_:)), name: .updateAQI, object: nil)
        
        // start the timer to update the AQI every 30 minutes
        
        
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
            button.title = AQIString
        }
    }
    
    // remove timer and notification center observer
    deinit {
        NotificationCenter.default.removeObserver(self, name: .updateAQI, object: nil)
    }
}

// create extension for notification center for our own notification name
extension Notification.Name {
    static let updateAQI = Notification.Name(rawValue: "updateAQI")
}
