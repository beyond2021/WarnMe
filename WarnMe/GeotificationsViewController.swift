//
//  GeotificationsViewController.swift
//  Geotify
//
//  Created by Ken Toh on 24/1/15.
//  Copyright (c) 2015 Ken Toh. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation // Setting Up a Location Manager and Permissions
let kSavedItemsKey = "savedItems"

class GeotificationsViewController: UIViewController, AddGeotificationsViewControllerDelegate, MKMapViewDelegate, CLLocationManagerDelegate {

  @IBOutlet weak var mapView: MKMapView!

  var geotifications = [Geotification]()
    
  let locationManager = CLLocationManager() // Setting Up a Location Manager and Permissions
    
  override func viewDidLoad() {
    super.viewDidLoad()
    // 1
    locationManager.delegate = self
    // 2
    locationManager.requestAlwaysAuthorization() // Make sure that the keys in PList file has no spaces in source code.
    // 3
    loadAllGeotifications()
    }

  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "addGeotification" {
      let navigationController = segue.destinationViewController as! UINavigationController
      let vc = navigationController.viewControllers.first as! AddGeotificationViewController
      vc.delegate = self
    }
  }

  // MARK: Loading and saving functions

  func loadAllGeotifications() {
    geotifications = []

    if let savedItems = NSUserDefaults.standardUserDefaults().arrayForKey(kSavedItemsKey) {
      for savedItem in savedItems {
        if let geotification = NSKeyedUnarchiver.unarchiveObjectWithData(savedItem as! NSData) as? Geotification {
          addGeotification(geotification)
        }
      }
    }
  }

  func saveAllGeotifications() {
    let items = NSMutableArray()
    for geotification in geotifications {
      let item = NSKeyedArchiver.archivedDataWithRootObject(geotification)
      items.addObject(item)
    }
    NSUserDefaults.standardUserDefaults().setObject(items, forKey: kSavedItemsKey)
    NSUserDefaults.standardUserDefaults().synchronize()
  }

  // MARK: Functions that update the model/associated views with geotification changes

  func addGeotification(geotification: Geotification) {
    geotifications.append(geotification)
    mapView.addAnnotation(geotification)
    addRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func removeGeotification(geotification: Geotification) {
    if let indexInArray = geotifications.indexOf(geotification) {
      geotifications.removeAtIndex(indexInArray)
    }

    mapView.removeAnnotation(geotification)
    removeRadiusOverlayForGeotification(geotification)
    updateGeotificationsCount()
  }

  func updateGeotificationsCount() {
    title = "PitStops (\(geotifications.count))"
    navigationItem.rightBarButtonItem?.enabled = (geotifications.count < 20) // This line disables the Add button in the navigation bar whenever the app reaches the limit.
    }

  // MARK: AddGeotificationViewControllerDelegate
/*
  func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
    controller.dismissViewControllerAnimated(true, completion: nil)
    // Add geotification
    let geotification = Geotification(coordinate: coordinate, radius: radius, identifier: identifier, note: note, eventType: eventType)
    addGeotification(geotification)
    saveAllGeotifications()
  }
*/
    //
    
    func addGeotificationViewController(controller: AddGeotificationViewController, didAddCoordinate coordinate: CLLocationCoordinate2D, radius: Double, identifier: String, note: String, eventType: EventType) {
        controller.dismissViewControllerAnimated(true, completion: nil)
        // 1
        let clampedRadius = (radius > locationManager.maximumRegionMonitoringDistance) ? locationManager.maximumRegionMonitoringDistance : radius
        
        let geotification = Geotification(coordinate: coordinate, radius: clampedRadius, identifier: identifier, note: note, eventType: eventType)
        addGeotification(geotification)
        // 2
        startMonitoringGeotification(geotification)
        
        saveAllGeotifications()
    }
    
    
    
    
    

  // MARK: MKMapViewDelegate

  func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
    let identifier = "myGeotification"
    if annotation is Geotification {
      var annotationView = mapView.dequeueReusableAnnotationViewWithIdentifier(identifier) as? MKPinAnnotationView
      if annotationView == nil {
        annotationView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: identifier)
        annotationView?.canShowCallout = true
        let removeButton = UIButton(type: .Custom)
        removeButton.frame = CGRect(x: 0, y: 0, width: 23, height: 23)
        removeButton.setImage(UIImage(named: "DeleteGeotification")!, forState: .Normal)
        annotationView?.leftCalloutAccessoryView = removeButton
      } else {
        annotationView?.annotation = annotation
      }
      return annotationView
    }
    return nil
  }
  
  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
    
     //if overlay is MKCircle {
      let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.lineWidth = 1.0
            circleRenderer.strokeColor = UIColor.purpleColor()
            circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
            return circleRenderer
    // }
    
   
     }
  
  
  
  

//  func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer? {
//    if overlay is MKCircle {
//      let circleRenderer = MKCircleRenderer(overlay: overlay)
//      circleRenderer.lineWidth = 1.0
//      circleRenderer.strokeColor = UIColor.purpleColor()
//      circleRenderer.fillColor = UIColor.purpleColor().colorWithAlphaComponent(0.4)
//      return circleRenderer
//    }
//    return nil
//  }

    /*
  func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
    // Delete geotification
    let geotification = view.annotation as! Geotification
    removeGeotification(geotification)
    saveAllGeotifications()
  }
*/
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        // Delete geotification
        let geotification = view.annotation as! Geotification
        stopMonitoringGeotification(geotification)   // Add this statement
        removeGeotification(geotification)
        saveAllGeotifications()
    }

    

  // MARK: Map overlay functions

  func addRadiusOverlayForGeotification(geotification: Geotification) {
    mapView?.addOverlay(MKCircle(centerCoordinate: geotification.coordinate, radius: geotification.radius))
  }

  func removeRadiusOverlayForGeotification(geotification: Geotification) {
    // Find exactly one overlay which has the same coordinates & radius to remove
    if let overlays = mapView?.overlays {
      for overlay in overlays {
        if let circleOverlay = overlay as? MKCircle {
          let coord = circleOverlay.coordinate
          if coord.latitude == geotification.coordinate.latitude && coord.longitude == geotification.coordinate.longitude && circleOverlay.radius == geotification.radius {
            mapView?.removeOverlay(circleOverlay)
            break
          }
        }
      }
    }
  }

  // MARK: Other mapview functions

  @IBAction func zoomToCurrentLocation(sender: AnyObject) {
    zoomToUserLocationInMapView(mapView)
  }
    
  // CLLocationManagerDelegate Methods
    //Get the user's location only when the app finishes asking for permission. The location manager calls locationManager(_:didChangeAuthorizationStatus:) whenever the authorization status changes
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.showsUserLocation = (status == .AuthorizedAlways)
    }
    
    
  // MARK : Registering Your Geofences
    /*
    In your app, the user geofence information is stored within your custom Geotification model. However, Core Location requires each geofence to be represented as a CLCircularRegion instance before it can be registered for monitoring. To handle this requirement, you’ll create a helper method that returns a CLCircularRegion from a given Geotification objec
*/
    
    
    func regionWithGeotification(geotification: Geotification) -> CLCircularRegion {
        // 1
        // You initialize a CLCircularRegion with the location of the geofence, the radius of the geofence and an identifier that allows iOS to distinguish between the registered geofences of a given app. The initialization is rather straightforward, as the Geotification model already contains the required properties
        
        let region = CLCircularRegion(center: geotification.coordinate, radius: geotification.radius, identifier: geotification.identifier)
        
        
        // 2
        // The CLCircularRegion instance also has two Boolean properties, notifyOnEntry and notifyOnExit. These flags specify whether geofence events will be triggered when the device enters and leaves the defined geofence, respectively. Since you’re designing your app to allow only one notification type per geofence, you set one of the flags to true while you set the other to false, based on the enum value stored in the Geotification object
        region.notifyOnEntry = (geotification.eventType == .OnEntry)
        region.notifyOnExit = !region.notifyOnEntry
        return region
    }
    
    
    //
    func startMonitoringGeotification(geotification: Geotification) {
        // 1
        // isMonitoringAvailableForClass(_:) determines if the device has the required hardware to support the monitoring of geofences. If monitoring is unavailable, you bail out entirely and alert the user accordingly. showSimpleAlertWithTitle(_:message:viewController) is a helper function in Utilities.swift that takes in a title and message and displays an alert view.
        
        if !CLLocationManager.isMonitoringAvailableForClass(CLCircularRegion) {
            showSimpleAlertWithTitle("Error", message: "Geofencing is not supported on this device!", viewController: self)
            return
        }
        
        
        
        // 2
        // Next, you check the authorization status to ensure that the app has also been granted the required permission to use Location Services. If the app isn’t authorized, it won’t receive any geofence-related notifications. However, in this case, you’ll still allow the user to save the geotification, since Core Location lets you register geofences even when the app isn’t authorized. When the user subsequently grants authorization to the app, monitoring for those geofences will begin automatically.
        
        if CLLocationManager.authorizationStatus() != .AuthorizedAlways {
            showSimpleAlertWithTitle("Warning", message: "Your geotification is saved but will only be activated once you grant Geotify permission to access the device location.", viewController: self)
        }
        
    
        // 3
        // You create a CLCircularRegion instance from the given geotification using the helper method you defined earlier.
        
        let region = regionWithGeotification(geotification)
        
        
        // 4
        // Finally, you register the CLCircularRegion instance with Core Location for monitoring
        
        
        locationManager.startMonitoringForRegion(region)
    }
    
    
    func stopMonitoringGeotification(geotification: Geotification) {
        for region in locationManager.monitoredRegions {
            if let circularRegion = region as? CLCircularRegion {
                if circularRegion.identifier == geotification.identifier {
                    locationManager.stopMonitoringForRegion(circularRegion)
                }
            }
        }
    }
    
    //MARK : Location manager Error Management
    
    // TODO Note: You’ll definitely want to handle these errors more robustly in your production apps. For example, instead of failing silently, you could inform the user what went wrong.
    
    func locationManager(manager: CLLocationManager, monitoringDidFailForRegion region: CLRegion?, withError error: NSError) {
        print("Monitoring failed for region with identifier: \(region!.identifier)")
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("Location Manager failed with the following error: \(error)")
    }
    
    
    
}
