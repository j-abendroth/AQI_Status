//
//  ViewController.swift
//  AQI Status
//
//  Created by John Abendroth on 9/15/20.
//  Copyright © 2020 John Abendroth. All rights reserved.
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
            button.title = AQIString
        }
    }
}

// create extension for notification center for our own notification name
extension Notification.Name {
    static let updateAQI = Notification.Name(rawValue: "updateAQI")
}
