//
//  ViewController.swift
//  CapitalOneATMBranchLocator
//
//  Created by Rajesh kumar Subbiah on 7/14/16.
//  Copyright © 2016 Rajesh kumar Subbiah. All rights reserved.
//

import UIKit
import MapKit
import Contacts

class ViewController: UIViewController {
    
    var currentAnnotation = Annotation()
    var atmsListArray:Array = [Annotation]()

    let atmReqURL = "http://api.reimaginebanking.com/atms"
    var lat:Double = 0.0 //= 38.9283
    var lng:Double = 0.0//= -77.1753
    var rad = 2
    let key = "19234714d799e8aba91c3d387cc7b9d8"
    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        //Map related
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func getATMList()
    {
        //Request URL:
        //http://api.reimaginebanking.com/atms?lat=38.9283&lng=-77.1753&rad=1&key=19234714d799e8aba91c3d387cc7b9d8
        
        let reqURL = "\(atmReqURL)?lat=\(lat)&lng=\(lng)&rad=\(rad)&key=\(key)"
        
        print("RequestURL is:\(reqURL)")
        
        //Call the webservices
        
        let requestURL: NSURL = NSURL(string: reqURL)!
        let urlRequest: NSMutableURLRequest = NSMutableURLRequest(URL: requestURL)
        let session = NSURLSession.sharedSession()
        let task = session.dataTaskWithRequest(urlRequest) {
            (data, response, error) -> Void in
            
            let httpResponse = response as! NSHTTPURLResponse
            let statusCode = httpResponse.statusCode
            
            if (statusCode == 200) {
                print("Everyone is fine, file downloaded successfully.")
                //Parse the data and load in to Data Model
                do {
                    let json = try NSJSONSerialization.JSONObjectWithData(data!, options:.AllowFragments)
                    
                    if let atmslist = json["data"] as? [[String: AnyObject]] {
                        if(atmslist.count == 0)
                        {
                            let alert = UIAlertController(title: "Oops!", message:"There is no ATM near you", preferredStyle: .Alert)
                            alert.addAction(UIAlertAction(title: "OK", style: .Default) { _ in })
                            self.presentViewController(alert, animated: true){}
                        }
                        else{
                        for atm in atmslist {
                            
                            let atmDetails:Annotation = Annotation()
                            
                            atmDetails._id = (atm["_id"] as? String)!
                            atmDetails.title = (atm["name"] as? String)!
                            let GeoCodes = atm["geocode"] as? [String:Double]
                            var geoCode1:GeoLoc = GeoLoc()
                            for geocode in GeoCodes!
                            {
                                let geokey = geocode.0
                                if(geokey == "lat")
                                {
                                    geoCode1.lat = geocode.1
                                }
                                else if(geokey == "lng")
                                {
                                    geoCode1.lng = geocode.1
                                }
                            }
                            atmDetails.geocode = geoCode1
                            atmDetails.coordinate = CLLocationCoordinate2DMake(geoCode1.lat, geoCode1.lng)
                            
                            atmDetails.accessibility = (atm["accessibility"] as? Bool)!
                            
                            let hrs = atm["hours"] as? [String]
                            for hr in hrs!
                            {
                                atmDetails.hours.append(hr)
                            }
                            var address1:Address = Address()
                            let addr = atm["address"] as? [String:String]
                            for addrs in addr!
                            {
                                let addkey = addrs.0
                                switch addkey
                                {
                                case "state":
                                    address1.state = addrs.1
                                case "zip":
                                    address1.zip = addrs.1
                                case "city":
                                    address1.city = addrs.1
                                case "street_name":
                                    address1.street_name = addrs.1
                                case "street_number":
                                    address1.street_number = addrs.1
                                default: break
                                }
                                
                            }
                            atmDetails.address = address1
                            atmDetails.subtitle = "\(address1.street_number) \(address1.street_name) \(address1.city) \(address1.state) \(address1.zip)"
                            let langs = atm["language_list"] as? [String]
                            for lang in langs!
                            {
                                atmDetails.language_list.append(lang)
                            }
                            atmDetails.amount_left = (atm["amount_left"] as? Int)!
                            
                            print(atmDetails.coordinate)
                            self.atmsListArray.append(atmDetails)
                        }
                        }

                    }
                    //Place the pins in the Map
                    self.mapView.addAnnotations(self.atmsListArray)
                    
                    self.mapView.delegate = self
                    
                }
                catch
                {
                    print("Error with Json: \(error)")
                }
            }
        }
        task.resume()
    }
    
    //Get the driving direction to ATM
    func getDirections(){
        
        let addressDict =
            [CNPostalAddressStreetKey: "\(currentAnnotation.address.street_number) \(currentAnnotation.address.street_name)",
             CNPostalAddressCityKey : currentAnnotation.address.city,
             CNPostalAddressStateKey: currentAnnotation.address.state,
             CNPostalAddressPostalCodeKey: currentAnnotation.address.zip]
        
        let place = MKPlacemark(coordinate: currentAnnotation.coordinate,
                                addressDictionary: addressDict)
        
        let mapItem = MKMapItem(placemark: place)

        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMapsWithLaunchOptions(launchOptions)

    }

}


extension ViewController : CLLocationManagerDelegate {
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print("location:: \(location.coordinate)")
            lat = location.coordinate.latitude
            lng = location.coordinate.longitude
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            if(lat != 0.0 && lng != 0.0)
            {
                getATMList()
            }
        }
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("error:: \(error)")
    }
}


extension ViewController : MKMapViewDelegate {
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView?{
        if annotation is MKUserLocation {
            //return nil so map view draws "blue dot" for standard user location
            return nil
        }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView?.pinTintColor = UIColor.greenColor()
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPointZero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "car"), forState: .Normal)
        button.addTarget(self, action: #selector(ViewController.getDirections), forControlEvents: .TouchUpInside)
        pinView?.leftCalloutAccessoryView = button
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        if(view.annotation != nil)
        {
            currentAnnotation = (view.annotation as? Annotation)!
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegionMake(currentAnnotation.coordinate, span)
            mapView.setRegion(region, animated: true)
        }
    }
    
    /*func mapView(mapView: MKMapView, regionWillChangeAnimated animated: Bool) {
        print("inside region will change")
    }
 */
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        print("inside region did change")
        lat = mapView.centerCoordinate.latitude
        print("Latitude:\(lat)")
        lng = mapView.centerCoordinate.longitude
        print("Longitude:\(lng)")
        getATMList();
    }
}
