//
//  EarthquakesViewController.swift
//  Quakes
//
//  Created by Paul Solt on 10/3/19.
//  Copyright © 2019 Lambda, Inc. All rights reserved.
//

import UIKit
import MapKit

extension String {
    static let annotationReuseIdentifier = "QuakeAnnotaionView"
}

class EarthquakesViewController: UIViewController {
		
    private let quakeFetcher = QuakeFetcher()
    
	// NOTE: You need to import MapKit to link to MKMapView
	@IBOutlet var mapView: MKMapView!
    
    private var userTrackingButton: MKUserTrackingButton!
    
    private let locationManager = CLLocationManager()
    
    var quakes: [Quake] = [] {
        didSet {
//            mapView.addAnnotations(quakes)
            // optimize to remove old ones and add new ones dynamically
            let oldQuakes = Set(oldValue)
            let newQuakes = Set(quakes)
            
            let addedQuakes = Array(newQuakes.subtracting(oldQuakes))
            let removedQuakes = Array(oldQuakes.subtracting(newQuakes))
            
            mapView.removeAnnotations(removedQuakes)
            mapView.addAnnotations(addedQuakes)
        }
    }
	
	override func viewDidLoad() {
		super.viewDidLoad()
        
        locationManager.requestWhenInUseAuthorization()
        
		userTrackingButton = MKUserTrackingButton(mapView: mapView)
        userTrackingButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userTrackingButton)
        
        NSLayoutConstraint.activate([
            userTrackingButton.leadingAnchor.constraint(equalTo: mapView.leadingAnchor, constant: 20),
            mapView.bottomAnchor.constraint(equalTo: userTrackingButton.bottomAnchor, constant: 20)
        ])
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: .annotationReuseIdentifier)
        fetchQuakes()
	}
    
    func fetchQuakes() {
        let visibleRegion = mapView.visibleMapRect
        
        quakeFetcher.fetchQuakes(in: visibleRegion) { (quakes, error) in
            if let error = error {
                print("Error fetching quakes: \(error)")
//                NSLog("Error fetching quakes: %@", error)
            }
            self.quakes = quakes ?? []
        }
    }
}

extension EarthquakesViewController: MKMapViewDelegate {
    func mapViewDidChangeVisibleRegion(_ mapView: MKMapView) {
        fetchQuakes()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard let quake = annotation as? Quake else { return nil }
        
        guard let annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: .annotationReuseIdentifier,
                                                                         for: quake) as? MKMarkerAnnotationView
            else { preconditionFailure("Missing the registered map annotation view.") }
        
        annotationView.glyphImage = #imageLiteral(resourceName: "QuakeIcon")
        
        if quake.magnitude >= 7 {
            annotationView.markerTintColor = .systemPurple
        } else if quake.magnitude >= 5 {
            annotationView.markerTintColor = .systemRed
        } else if quake.magnitude >= 3 {
            annotationView.markerTintColor = .systemOrange
        } else {
            annotationView.markerTintColor = .systemYellow
        }
        
        annotationView.canShowCallout = true
        let detailView = QuakeDetailView()
        detailView.quake = quake
        annotationView.detailCalloutAccessoryView = detailView
        
        return annotationView
    }
}
