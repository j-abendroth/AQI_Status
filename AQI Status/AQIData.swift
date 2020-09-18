//
//  AQIData.swift
//  AQI Status
//
//  Class designed to hold all the current AQI data fetched
//

import Cocoa
import CoreLocation

public class AQIData {
    public var zipCode: String
    public var lat: String?
    public var long: String?
    
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
            // if so, update the location values to nil
            if let error = error {
                print("Unable to get coordinates from current zip code: \(error)")
            }
            else {
                var location: CLLocation?
                // we only care about the first placemark returned, even if > 1 are returned
                // just want an approximation for location, so first one is good enough
                if let placemark = placemarks?[0] {
                    location = placemark.location
                }
                print("Here")
                // break coordinate down into lat & long, update class variables
                if let location = location {
                    let coordinate = location.coordinate
                    self.lat = "\(coordinate.latitude)"
                    self.long = "\(coordinate.longitude)"
                }
            }
        }
        // signal we're done with the GLGeocoder api call
        
    }
    
    // shared instance of the AQI data
    // chose singleton so that I can just throw AQI data in here and pull from it wherever
    // default starting zip is Santa Cruz
    static let shared = AQIData(zip: "92782")
}
