//
//  ATMDataModel.swift
//  CapitalOneATMBranchLocator
//
//  Created by Rajesh kumar Subbiah on 7/14/16.
//  Copyright © 2016 Rajesh kumar Subbiah. All rights reserved.
//

import Foundation
import MapKit

//Data Model for ATM
struct Address
{
    var state:String = ""
    var zip:String = ""
    var city:String = ""
    var street_name:String = ""
    var street_number:String = ""
}

struct GeoLoc
{
    var lat:Double = 0.0
    var lng:Double = 0.0
}

class Annotation: NSObject, MKAnnotation
{
    var coordinate: CLLocationCoordinate2D
    var title: String?
    var subtitle: String?
    var _id:String
    var geocode:GeoLoc
    var accessibility:Bool
    var hours:[String]
    var address:Address
    var language_list:[String]
    var amount_left:Int
    
    override init() {
        coordinate = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)
        title = ""
        subtitle = ""
        _id = ""
        geocode = GeoLoc()
        accessibility = false
        hours = [String]()
        address = Address()
        language_list = [String]()
        amount_left = 0
        
    }
}
