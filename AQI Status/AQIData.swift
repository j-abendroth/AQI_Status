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
    public var nwLat: Double?
    public var nwLng: Double?
    public var seLat: Double?
    public var seLng: Double?
    
    public var AQI: Float?
    
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
                    self.genBoundryBox()
                    self.fetchJson()
                } else {
                    // if we get here, set coordinate to nil to indicate error
                    self.zipCoordinate = nil
                }
            }
        }
        // signal we're done with the GLGeocoder api call
    }
    
    // inaccurate way to calculate the bounding box, but simple
    // decided to settle for a decent approximation rather than work out a ton of math
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
    
    public func fetchJson() {
        
        if let nwLat = self.nwLat, let nwLng = self.nwLng, let seLat = self.seLat, let seLng = self.seLng {
            let urlString = "https://www.purpleair.com/data.json?opt=1/i/mAQI/a10/cC4&fetch=true&nwlat=" + "\(nwLat)" + "&selat=" + "\(seLat)" + "&nwlng=" + "\(nwLng)" + "&selng=" + "\(seLng)" + "&fields=pm_1,"
            print(urlString)
            
            guard let url = URL(string: urlString) else {
                // error assigning url, can't complete get request
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, err) in
                if err != nil {
                    // caught an error
                    print("caught an error")
                    return
                }
                
                guard response != nil else {
                    // no response from api
                    // possibly rate limited
                    print("no response")
                    return
                }
                
                guard let data = data else {
                    // no data returned from api
                    // either rate limited or filtering distance is too low
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        if let data = json["data"] as? Array<Array<Any>> {
                            // value is now an array of any in the array data
                            // loop through all value arrays
                            for value in data {
                                // 5th field is the type, where 1 is inside
                                // only want outside sensors, so look for 0
                                // also 10th field is a flag from purple air
                                // if flag is 1, it's marked as bad data
                                if value[4] as! Int == 0, value[9] as! Int == 0{
                                    print(value[2])
                                }
                            }
                        }
                    }
                } catch let err {
                    print(err.localizedDescription)
                }
            }
            task.resume()
            
            
            
        } else {
            // return, one of the class coordinates was nil
        }
        
        
        
    }
    
    public func aqiFromPM(pmValue: Float) {
        // error check pm value
        // if anything is wrong, just set aqi to nil
        if pmValue.isNaN {
            self.AQI = nil
        }
        if pmValue < 0 {
            self.AQI = pmValue
        }
        if (pmValue > 1000) {
            self.AQI = nil
        }
        
        if pmValue > 350.5 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 500, Il: 401, BPh: 500, BPl: 350.5)
        } else if pmValue > 250.5 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 400, Il: 301, BPh: 350.4, BPl: 250.5)
        } else if pmValue > 150.5 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 300, Il: 201, BPh: 250.4, BPl: 150.5)
        } else if pmValue > 55.5 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 200, Il: 151, BPh: 150.4, BPl: 55.5)
        } else if pmValue > 35.5 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 150, Il: 101, BPh: 55.4, BPl: 35.5)
        } else if pmValue > 12.1 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 100, Il: 51, BPh: 35.4, BPl: 12.1)
        } else if pmValue >= 0 {
            self.AQI = calcAQI(Cp: pmValue, Ih: 50, Il: 0, BPh: 12, BPl: 0)
        }
    }
    
    // taken from purple air's FAQ
    public func calcAQI(Cp: Float, Ih: Float, Il: Float, BPh: Float, BPl: Float) -> Float {
        let a = (Ih - Il)
        let b = (BPh - BPl)
        let c = (Cp - BPl)
        
        var aqi = ((a/b) * c + Il)
        aqi.round()
        
        return aqi
    }
    
    public func updateData() {
        
    }
    
    
    
    // shared instance of the AQI data
    // chose singleton so that I can just throw AQI data in here and pull from it wherever
    // default starting zip is Santa Cruz
    static let shared = AQIData(zip: "95062")
}
