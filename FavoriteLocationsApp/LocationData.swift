import UIKit
import MapKit
import CoreData
import CoreLocation

//açılışta haritada gözüken yer anlık konum olsun. değişince işlem yapılmasın
class LocationData: UIViewController {
    var incomingLocationID: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationManager = CLLocationManager()
    @IBOutlet var locationNameTextField: UITextField!
    @IBOutlet var locationNoteTextField: UITextField!
    @IBOutlet var mapView: MKMapView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(closeKeyboard))
        view.addGestureRecognizer(gestureRecognizer)
        locationNameTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: .editingChanged)
    }
    
    @objc func textFieldDidChange(_ textField: UITextField) {
        if textField.text == "" {
            navigationItem.rightBarButtonItem?.isEnabled = false
        } else {
            navigationItem.rightBarButtonItem?.isEnabled = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if incomingLocationID != nil {
            fetchData()
        } else {
            let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(chooseLocation(gestureRecognizer: )))
            gestureRecognizer.minimumPressDuration = 2
            mapView.addGestureRecognizer(gestureRecognizer)
            locationManager.stopUpdatingLocation()
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveLocation))
            navigationItem.rightBarButtonItem?.isEnabled = false
        }
    }
    
    @objc func closeKeyboard(){
        view.endEditing(true)
    }
    
    func fetchData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
        request.predicate = NSPredicate(format: "id = %@", incomingLocationID!)
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request) as! [NSManagedObject]
            for item in result {
                if let name = item.value(forKey: "name") as? String {
                    locationNameTextField.text = name
                    if let note = item.value(forKey: "note") as? String {
                        locationNoteTextField.text = note
                        if let latitude = item.value(forKey: "latitude") as? Double {
                            if let longitude = item.value(forKey: "longitude") as? Double {
                                locationManager.stopUpdatingLocation()
                                let coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                                let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                                let region = MKCoordinateRegion(center: coordinate, span: span)
                                mapView.setRegion(region, animated: true)
                                let annotation = MKPointAnnotation()
                                annotation.coordinate = coordinate
                                annotation.title = name
                                annotation.subtitle = note
                                mapView.addAnnotation(annotation)
                            }
                        }
                    }
                }
                break
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    @objc func chooseLocation(gestureRecognizer: UILongPressGestureRecognizer){
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: mapView)
            let touchLocation = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            locationLatitude = touchLocation.latitude
            locationLongitude = touchLocation.longitude
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchLocation
            if let name = locationNameTextField.text {
                annotation.title = name
            }
            if let note = locationNoteTextField.text {
                annotation.subtitle = note
            }
            mapView.addAnnotation(annotation)
//            mapView.showsUserLocation = false
        }
    }
    
    @objc func saveLocation(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let newLocation = NSEntityDescription.insertNewObject(forEntityName: "Locations", into: context)
        newLocation.setValue(UUID(), forKey: "id")
        if let name = locationNameTextField.text {
            newLocation.setValue(name, forKey: "name")
        }
        if let note = locationNoteTextField.text {
            newLocation.setValue(note, forKey: "note")
        }
        newLocation.setValue(locationLatitude, forKey: "latitude")
        newLocation.setValue(locationLongitude, forKey: "longitude")
        appDelegate.saveContext()
        navigationController?.popViewController(animated: true)
    }
    
}

extension LocationData: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if incomingLocationID ==  nil {
            let coordinate = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: coordinate, span: span)
            mapView.showsUserLocation = true
            mapView.setRegion(region, animated: true)
        }
    }
    
}

extension LocationData: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let annotationID = "annotation"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationID)
        if pinView == nil {
            pinView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: annotationID)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

    }
}


