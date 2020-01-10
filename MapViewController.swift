//
//  MapViewController.swift
//  GMap
//
//  Created by Ashok kumar T on 26/04/19.
//  Copyright © 2019 Spericorn. All rights reserved.
//

import UIKit
import GoogleMaps

class MapViewController: UIViewController {
    
    @IBOutlet weak var viewMap: UIView!
    
    var locationManager = CLLocationManager()
    var markersArray = [GMSMarker]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func loadView() {
        
        // Create a GMSCameraPosition that tells the map to display the
        // coordinate -33.86,151.20 at zoom level 6.
        let camera = GMSCameraPosition.camera(withLatitude: -33.86, longitude: 151.20, zoom: 6.0)
        let mapView = GMSMapView.map(withFrame: CGRect.zero, camera: camera)
        mapView.isMyLocationEnabled = true
        
        do {
            // Set the map style by passing a valid JSON string.
            mapView.mapStyle = try GMSMapStyle(jsonString: kMapStyle)
        } catch {
            NSLog("One or more of the map styles failed to load. \(error)")
        }
        
        view = mapView
        
        self.locationManager.delegate = self
        self.locationManager.startUpdatingLocation()
        
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    //Location Manager delegates
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        
        guard let location = locations.last else { return }
        
        markersArray.append(
            MarkerModel(
                position: CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude),
                title: "Sydney",
                snippet: "Australia"
                ).createMarker(in: self.view)
        )
        
        
        for i in 0..<10 {
            
            self.markersArray.append(
                MarkerModel(
                    position: CLLocationCoordinate2D(latitude: location.coordinate.latitude + Double(i)/1000.0, longitude: location.coordinate.longitude - Double(i)/1000.0),
                    title: "Sydney",
                    snippet: "Australia"
                    ).createMarker(in: self.view)
            )
            
        }
        
        
        let camera = GMSCameraPosition.camera(withLatitude: location.coordinate.latitude, longitude: location.coordinate.longitude, zoom: 17.0)
        
        (self.view as? GMSMapView)?.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.locationManager.stopUpdatingLocation()
        
    }
}


class MarkerModel {
    
    var position    : CLLocationCoordinate2D!
    var title       : String = ""
    var snippet     : String?
    
    init(position: CLLocationCoordinate2D, title: String, snippet: String?) {
        self.position = position
        self.title = title
        self.snippet = snippet
    }
    
    func createMarker(in view: UIView) -> GMSMarker {
        let marker = GMSMarker()
        marker.position = position
        marker.title = title
        marker.snippet = snippet
        marker.appearAnimation = .pop
        marker.map = (view as? GMSMapView)
        return marker
    }
}

let kMapStyle = """
[
    {
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#212121"
        }
        ]
    },
    {
        "elementType": "labels.icon",
        "stylers": [
        {
        "visibility": "off"
        }
        ]
    },
    {
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#757575"
        }
        ]
    },
    {
        "elementType": "labels.text.stroke",
        "stylers": [
        {
        "color": "#212121"
        }
        ]
    },
    {
        "featureType": "administrative",
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#757575"
        }
        ]
    },
    {
        "featureType": "administrative.country",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#9e9e9e"
        }
        ]
    },
    {
        "featureType": "administrative.locality",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#bdbdbd"
        }
        ]
    },
    {
        "featureType": "poi",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#757575"
        }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#181818"
        }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#616161"
        }
        ]
    },
    {
        "featureType": "poi.park",
        "elementType": "labels.text.stroke",
        "stylers": [
        {
        "color": "#1b1b1b"
        }
        ]
    },
    {
        "featureType": "road",
        "elementType": "geometry.fill",
        "stylers": [
        {
        "color": "#2c2c2c"
        }
        ]
    },
    {
        "featureType": "road",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#8a8a8a"
        }
        ]
    },
    {
        "featureType": "road.arterial",
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#373737"
        }
        ]
    },
    {
        "featureType": "road.highway",
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#3c3c3c"
        }
        ]
    },
    {
        "featureType": "road.highway.controlled_access",
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#4e4e4e"
        }
        ]
    },
    {
        "featureType": "road.local",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#616161"
        }
        ]
    },
    {
        "featureType": "transit",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#757575"
        }
        ]
    },
    {
        "featureType": "water",
        "elementType": "geometry",
        "stylers": [
        {
        "color": "#000000"
        }
        ]
    },
    {
        "featureType": "water",
        "elementType": "labels.text.fill",
        "stylers": [
        {
        "color": "#3d3d3d"
        }
        ]
    }
]
"""
