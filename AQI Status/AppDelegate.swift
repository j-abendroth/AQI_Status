//
//  AppDelegate.swift
//  AQI Status
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    // create system wide instance of a status bar item
     let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    
    // create an initialized popover variable to be toggled
    let popover = NSPopover()
    
    // create object for event monitor
    var eventMonitor: EventMonitor?
    

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // set up the button to be displayed in the status bar
        if let button = self.statusItem.button {
            // actual value to be displayed in the menu bar
            // going to use a text title that will be updated to current AQI
            button.title = "--"
            // if button is clicked, display the menu popover
            button.action = #selector(AppDelegate.togglePopover(_:))
        }
        
        // create new instance of a view controller for the popover
        self.popover.contentViewController = ViewController.newViewController()
        self.popover.animates = true
        
        self.eventMonitor = EventMonitor(mask: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(sender: event)
            }
        }
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
        self.eventMonitor?.start()
        
    }

    func closePopover(sender: Any?)  {
        self.popover.performClose(sender)
        self.eventMonitor?.stop()
    }

}
