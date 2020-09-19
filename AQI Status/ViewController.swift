//
//  ViewController.swift
//  AQI Status
//
//  Created by John Abendroth on 9/15/20.
//  Copyright © 2020 John Abendroth. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var zipCodeTextField: NSTextField!
    func controlTextDidEndEditing(_ obj: Notification) {
        // once the zip code is entered, update the stored zip code value
        AQIData.shared.zipCode = zipCodeTextField.stringValue
        print("Changed text = \(zipCodeTextField.stringValue)\n")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        zipCodeTextField.delegate = self

        // set default zip code entry to Santa Cruz
        zipCodeTextField.stringValue = "95062"
        
        // start the timer to update the AQI every 30 minutes
        
        
        
        AQIData.shared.fetchCoordinates()
        //AQIData.shared.test()
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

}

