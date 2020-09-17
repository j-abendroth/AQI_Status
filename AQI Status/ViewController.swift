//
//  ViewController.swift
//  AQI Status
//
//  Created by John Abendroth on 9/15/20.
//  Copyright © 2020 John Abendroth. All rights reserved.
//

import Cocoa

class ViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var zipCodeTextField: NSTextFieldCell!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // set default zip code entry to Santa Cruz
        zipCodeTextField.stringValue = "95060"
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

