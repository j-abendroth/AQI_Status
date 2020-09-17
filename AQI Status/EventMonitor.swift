//
//  EventMonitor.swift
//  AQI Status
//
//  Class designed to monitor for events (clicks) outside the popover menu displayed

import Cocoa

public class EventMonitor {
    private var monitor: Any?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> Void
  
    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> Void) {
        self.mask = mask
        self.handler = handler
    }
  
    deinit {
        stop()
    }
  
    public func start() {
        self.monitor = NSEvent.addGlobalMonitorForEvents(matching: self.mask, handler: self.handler)
    }
  
    public func stop() {
        if let eventMonitor = self.monitor {
            NSEvent.removeMonitor(eventMonitor)
            self.monitor = nil
        }
    }
}
