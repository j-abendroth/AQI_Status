//
//  AppDelegate.swift
//  AQI Status
//
//  Created by John Abendroth on 9/15/20.
//  Copyright © 2020 John Abendroth. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // create system wide instance of a status bar item
     let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    // creeate an initialized popover variable to be toggled
    let popover = NSPopover()

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // set up the button to be displayed in the status bar
        if let button = self.statusItem.button {
            // actual value to be displayed in the menu bar
            // going to use a text title that will be updated to current AQI
            button.title = "test 150"
            // if button is clicked, display the menu popover
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        // create new instance of a view controller for the popover
        self.popover.contentViewController = ViewController.newViewController()
        self.popover.animates = false
        
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    // function to toggle the menu popover when the AQI score is clicked
    @objc func togglePopover(_ sender: NSStatusItem) {
        if self.popover.isShown {
            closePopover(sender: sender)
        }
        else {
            showPopover(sender: sender)
        }
    }

    func showPopover(sender: Any?) {
        if let button = self.statusItem.button {
            self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
    }

    func closePopover(sender: Any?)  {
        self.popover.performClose(sender)
    }

}

