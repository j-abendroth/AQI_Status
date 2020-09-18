//
//  AQIData.swift
//  AQI Status
//
//  Class designed to hold all the current AQI data fetched
//

import Cocoa
import CoreLocation
import MapKit

public class AQIData {
    public var zipCode: String
    public var zipCoordinate: CLLocationCoordinate2D?
    public var nwLat: CLLocationDegrees?
    public var nwLng: CLLocationDegrees?
    public var seLat: CLLocationDegrees?
    public var seLng: CLLocationDegrees?
    
    public init(zip: String) {
        self.zipCode = zip
    }
    
    // public function used to update the current coordinates stored in the class
    // will forward geocode the currently stored zip code data
    public func fetchCoordinates() {
        let geocoder = CLGeocoder()
        // call the CLGeocoder api on the current zip code
        geocoder.geocodeAddressString(zipCode) { (placemarks, error) in
            // check to make sure the geocoder didn't return an error
            // if so, update the coordinate to nil
            if let error = error {
                print("Unable to get coordinates from current zip code: \(error)")
                self.zipCoordinate = nil
            }
            else {
                var location: CLLocation?
                // we only care about the first placemark returned, even if > 1 are returned
                // just want an approximation for location, so first one is good enough
                if let placemark = placemarks?[0] {
                    location = placemark.location
                }
                // if location was set successfully, set our class coordinate equal to its coordinate
                if let location = location {
                    self.zipCoordinate = location.coordinate
                } else {
                    // if we get here, set coordinate to nil to indicate error
                    self.zipCoordinate = nil
                }
            }
        }
        // signal we're done with the GLGeocoder api call
    }
    
    public func genBoundryBox() {
        // default span is 1.5 miles for testing
        // 1.5 mi = ~2400 m
        if let center = self.zipCoordinate {
            let region = MKCoordinateRegion(center: center, latitudinalMeters: 2400, longitudinalMeters: 2400)
            self.nwLat = center.latitude + (0.5 * (region.span.latitudeDelta))
            self.nwLng = center.longitude - (0.5 * (region.span.longitudeDelta))
            self.seLat = center.latitude - (0.5 * (region.span.latitudeDelta))
            self.seLng = center.longitude + (0.5 * (region.span.longitudeDelta))
            
            //print("NW: \(self.nwLat as Optional), \(self.nwLng as Optional)\n")
            //print("SE: \(self.seLat as Optional), \(self.seLng as Optional)\n")
            
        } else {
            //return a failure, the coordinate wasn't updated
        }
    }
    
    public func updateData() {
        
    }
    
    // shared instance of the AQI data
    // chose singleton so that I can just throw AQI data in here and pull from it wherever
    // default starting zip is Santa Cruz
    static let shared = AQIData(zip: "95062")
}
