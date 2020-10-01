//
//  AQIData.swift
//  AQI Status
//
//  Class with responsibilty of getting Purple Air API Data
//  Used to store Purple Air AQI Data for when user requests to use Purple Air
//

import Cocoa
import CoreLocation
import MapKit

public class AQIData {
    public var zipCode: String
    public var cityName: String
    public var stateName: String
    public var filterDistance: Double
    public var AQI: Float?
    public var AQandU: Bool
    public var LRAPA: Bool
    
    private var zipCoordinate: CLLocationCoordinate2D?
    private var PMArr: [(pmValue: Float, coordinate: CLLocationCoordinate2D)]
    private var nwLat: Double?
    private var nwLng: Double?
    private var seLat: Double?
    private var seLng: Double?
    
    public init(zip: String) {
        self.zipCode = zip
        self.cityName = "-"
        self.stateName = "-"
        self.filterDistance = 2.0 // default filter distance set to 2 mi
        self.PMArr = []
        self.AQandU = false
        self.LRAPA = false
    }
    
    enum coordinateError: Error {
        case geocodeError
        case missingLocation
        case missingCity
        case missingState
    }
    
    // function used to get location data based on a zip code
    // will forward geocode the currently stored zip code data and return the info to the completion handler
    private func fetchCoordinates(completion: @escaping (Result <(zipCoordinate: CLLocationCoordinate2D, cityName: String, stateName: String), coordinateError>) -> Void) {
        let geocoder = CLGeocoder()
        // call the CLGeocoder api on the current zip code
        geocoder.geocodeAddressString(self.zipCode) { (placemarks, error) in
            // check to make sure the geocoder didn't return an error
            // if so, set completion to failure and return
            guard error == nil else {
                completion(.failure(.geocodeError))
                return
            }
            
            var location: CLLocation?
            var city: String?
            var state: String?
            
            // we only care about the first placemark returned, even if > 1 are returned
            // just want an approximation for location, so first one is good enough
            if let placemark = placemarks?[0] {
                location = placemark.location
                city = placemark.locality
                state = placemark.administrativeArea
            }
            
            // test if the geocoder placemark returned each of the 3 things we need
            // if any 1 is missing, set failure and return
            guard let zipCoordinate = location?.coordinate else {
                completion(.failure(.missingLocation))
                return
            }
            
            guard let cityName = city else {
                completion(.failure(.missingCity))
                return
            }
            
            guard let stateName = state else {
                completion(.failure(.missingState))
                return
            }
            
            // else everything is there and we can return success
            // we're returning a tuple with the 3 different values we want
            completion(.success((zipCoordinate: zipCoordinate, cityName: cityName, stateName: stateName)))
        }
    }
    
    enum boundryError: Error {
        case zipCoordinateNil
    }
    
    // inaccurate way to calculate the bounding box, but simple
    // decided to settle for a decent approximation rather than work out a ton of math
    // function is NOT asynchronous but decided to use a completion handler as well to stay consistent with everything else
    private func genBoundryBox(completion: @escaping (Result <(nwLat: Double, nwLng: Double, seLat: Double, seLng: Double), boundryError>) -> Void) {
        // going to cache all sensors within the max 10 mi filter distance
        // 10 mi = ~16,100 m
        if let center = self.zipCoordinate {
            let region = MKCoordinateRegion(center: center, latitudinalMeters: 16100, longitudinalMeters: 16100)
            let nwLat = center.latitude + (0.5 * (region.span.latitudeDelta))
            let nwLng = center.longitude - (0.5 * (region.span.longitudeDelta))
            let seLat = center.latitude - (0.5 * (region.span.latitudeDelta))
            let seLng = center.longitude + (0.5 * (region.span.longitudeDelta))
            
            completion(.success((nwLat, nwLng, seLat, seLng)))
        } else {
            //return a failure, the coordinate wasn't updated
            completion(.failure(.zipCoordinateNil))
        }
    }
    
    enum PurpleAirError: Error {
        case badURL
        case requestFailed
        case dataFailure
        case URLSessionError
        case jsonDecodeError
        case coordinateError
    }
    
    // main function to handle api call to purple air
    // return the array of json parsed PMValues and coordinates to the completion handler if successfull
    // otherwise send a result type of failure with the case
    private func fetchPurpleAir(completion: @escaping (Result<[(pmValue: Float, coordinate: CLLocationCoordinate2D)], PurpleAirError>) -> Void) {
        if let nwLat = self.nwLat, let nwLng = self.nwLng, let seLat = self.seLat, let seLng = self.seLng {
            let urlString = "https://www.purpleair.com/data.json?opt=1/i/mAQI/a10/cC4&fetch=true&nwlat=" + "\(nwLat)" + "&selat=" + "\(seLat)" + "&nwlng=" + "\(nwLng)" + "&selng=" + "\(seLng)" + "&fields=pm_1,"
            print(urlString)
            
            guard let url = URL(string: urlString) else {
                // error assigning url, can't complete get request
                completion(.failure(.badURL))
                return
            }
            
            let task = URLSession.shared.dataTask(with: url) { (data, response, err) in
                if err != nil {
                    // caught an error
                    completion(.failure(.URLSessionError))
                }
                
                guard response != nil else {
                    // no response from api
                    // possibly rate limited
                    completion(.failure(.requestFailed))
                    return
                }
                
                guard let data = data else {
                    // no data returned from api
                    // either rate limited or filtering distance is too low
                    completion(.failure(.dataFailure))
                    return
                }
                
                do {
                    if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        var PMArr: [(pmValue: Float, coordinate: CLLocationCoordinate2D)] = []
                        
                        if let data = json["data"] as? Array<Array<Any>> {
                            // value is now an array of any in the array data
                            // loop through all value arrays
                            for value in data {
                                // 5th field is the type, where 1 is inside
                                // only want outside sensors, so look for 0
                                // also 10th field is a flag from purple air
                                // if flag is 1, it's marked as bad data
                                if value[4] as! Int == 0, value[9] as! Int == 0{
                                    // take all values as NSNumber since that's JSON standard
                                    // avoids the bug where NSNumber wouldn't downcast to float because of loss of precision due to 64bit vs 32bit fp
                                    // https://stackoverflow.com/a/50019421
                                    let PMValue = value[2] as! NSNumber
                                    let lat = value[6] as! NSNumber
                                    let lng = value[7] as! NSNumber
                                    let coordinate = CLLocationCoordinate2DMake(lat.doubleValue, lng.doubleValue)
                                    PMArr.append((PMValue.floatValue, coordinate))
                                }
                            }
                        }
                        // returning the completion for the PMarr
                        // put outside the if let statement so that if the deserialization fails it just returns an empty array
                        completion(.success(PMArr))
                    }
                } catch let err {
                    completion(.failure(.jsonDecodeError))
                    print(err.localizedDescription)
                }
            }
            task.resume()
            
        } else {
            // return, one of the class coordinates was nil
            completion(.failure(.coordinateError))
        }
    }
    
    // public calc pm function
    // called within updateData() or can be called separate
    // should be called separate if the filter region is changed, will then recalculate aqi based on cached PM values
    public func calcPM() {
        if let center = self.zipCoordinate {
            // convert our set filter distance in miles to meters
            let meters = self.filterDistance * 1609
            let region = MKCoordinateRegion(center: center, latitudinalMeters: meters, longitudinalMeters: meters)
            
            var pmSum: Float = 0
            var count: Float = 0
            for tuple in self.PMArr {
                if isCoordinate(coordinate: tuple.coordinate, region: region) {
                    print (tuple.pmValue)
                    pmSum += tuple.pmValue
                    count += 1
                }
            }
            // average the sum of the PM 2.5 measurements by the number of tuples we found were in the filter distance
            // if count is 0, pmSum is 0 so just set the AQI to that
            if count > 0 {
                pmSum = pmSum / count
                
                // check if conversions selected
                // conversion equations taken from Purple Air's website
                if self.AQandU {
                    pmSum = (0.778 * pmSum) + 2.65
                }
                
                else if self.LRAPA {
                    pmSum = (0.5 * pmSum) - 0.66
                }
            }
            setAQI(pmValue: pmSum)
        }
    }
    
    // private helper function for calcPM
    // returns if a coordinate is in the set filter region
    private func isCoordinate (coordinate: CLLocationCoordinate2D, region: MKCoordinateRegion) -> Bool {
        let center = region.center
        var nwLat: Double
        var nwLng: Double
        var seLat: Double
        var seLng: Double
        
        nwLat = center.latitude - (0.5 * (region.span.latitudeDelta))
        nwLng = center.longitude - (0.5 * (region.span.longitudeDelta))
        seLat = center.latitude + (0.5 * (region.span.latitudeDelta))
        seLng = center.longitude + (0.5 * (region.span.longitudeDelta))
        
        return (coordinate.latitude >= nwLat && coordinate.latitude <= seLat && coordinate.longitude >= nwLng && coordinate.longitude <= seLng)
    }
    
    // take a raw PM2.5 value and set class AQI value with a calculated AQI
    // function algorithm taken from Purple Air FAQ
    private func setAQI(pmValue: Float) {
        // error check pm value
        // if anything is wrong, just set aqi to nil
        if pmValue.isNaN {
            self.AQI = nil
        }
        if pmValue <= 0 {
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
        
        // post notification to update UI now that clss AQI value is updated
        NotificationCenter.default.post(name: .updateAQI, object: nil)
        
        print(pmValue)
        print(self.AQI as Any)
    }
    
    // taken from purple air's FAQ
    // private helper function to do the actual AQI calc
    private func calcAQI(Cp: Float, Ih: Float, Il: Float, BPh: Float, BPl: Float) -> Float {
        let a = (Ih - Il)
        let b = (BPh - BPl)
        let c = (Cp - BPl)
        
        var aqi = ((a/b) * c + Il)
        aqi.round()
        
        return aqi
    }
    
    public func getAQIDescription() -> String {
        guard let aqi = self.AQI else {
            return "--"
        }
        
        if aqi >= 301 {
            return "Hazardous"
        } else if aqi >= 201 {
            return "Very Unhealthy"
        } else if aqi >= 151 {
            return "Unhealthy"
        } else if aqi >= 101 {
            return "Unhealthy for Sensitive Groups"
        } else if aqi >= 51 {
            return "Moderate"
        } else if aqi >= 0 {
            return "Good"
        } else {
            return "--"
        }
    }
    
    // public function which should be called whenever a new zip code is input
    // use this to update the aqi value outside the class
    // runs the processing on a background thread and synchronizes the api calls
    public func updateData() {
        DispatchQueue.global(qos: .userInitiated).async {
            // set semaphore equal to 0 to start
            // fetchCoordinates() is async so semaphore will be decremented right away
            // block on semaphore.wait() until coordinates are returned
            var semaphore = DispatchSemaphore(value: 0)
            
            self.fetchCoordinates() { (result) in
                switch result {
                case .success((let zipCoordinate, let cityName, let stateName)):
                    self.zipCoordinate = zipCoordinate
                    self.cityName = cityName
                    self.stateName = stateName
                    // increment semaphore to continue
                    semaphore.signal()
                case .failure(let error):
                    // error occured in getting coordinates from geocoder
                    // reset all the values
                    self.updateError()
                    print(error.localizedDescription)
                    return
                }
            }
            semaphore.wait()
            
            // genBoundryBox is NOT asynchronous
            // no need to use semaphore
            self.genBoundryBox() { (result) in
                switch result {
                case .success((let nwLat, let nwLng, let seLat, let seLng)):
                    self.nwLat = nwLat
                    self.nwLng = nwLng
                    self.seLat = seLat
                    self.seLng = seLng
                case .failure(let error):
                    self.updateError()
                    print(error.localizedDescription)
                    return
                }
            }
            
            self.fetchPurpleAir() { (result) in
                switch result {
                case .success(let PMArr):
                    // update class's pm array to the newest returned one
                    self.PMArr = PMArr
                    semaphore.signal()
                case .failure(let error):
                    self.updateError()
                    print(error.localizedDescription)
                    return
                }
            }
            semaphore.wait()
            
            // all async calls are done
            // now just calc the AQI value and set it
            self.calcPM()
        }
    }
    
    private func updateError() {
        // clear all data values since something went wrong updating the aqi data
        self.zipCoordinate = nil
        self.cityName = "--"
        self.stateName = "--"
        
        // reset individual coordinate parts so that the url can't be made
        self.nwLat = nil
        self.nwLng = nil
        self.seLat = nil
        self.seLng = nil
        
        // set PM array equal to new empty array to clear it
        self.PMArr = []
        
        // weird exception sometimes thrown here if let alert = NSAlert() is on a background thread
        /*
         Terminating app due to uncaught exception 'NSInternalInconsistencyException', reason: 'NSWindow drag regions should only be invalidated on the Main Thread!'
         */
        // because of this I just scheduled it all for the main thread
        DispatchQueue.main.async {
            // post alert that updating failed
            let alert = NSAlert()
            alert.messageText = "Oops"
            alert.informativeText = "AQI data update failed. Please try again in a few seconds"
            alert.addButton(withTitle: "Okay")
            alert.runModal()
        }
    }
    
    // shared instance of the AQI data
    // chose singleton so that I can just throw AQI data in here and pull from it wherever
    // default starting zip is Santa Cruz
    static let shared = AQIData(zip: "95062")
}
