import UIKit
import CoreData

class LocationList: UIViewController {
    var selectedLocationID: String?
    var locationNames = [String]()
    var locationIDs = [String]()
    @IBOutlet var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        fetchData()
        tableView.reloadData()
    }
    
    func fetchData(){
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
        request.returnsObjectsAsFaults = false
        do {
            let result = try context.fetch(request)
            locationNames.removeAll(keepingCapacity: false)
            locationIDs.removeAll(keepingCapacity: false)
            for item in result as! [NSManagedObject] {
                if let id = item.value(forKey: "id") as? UUID {
                    if let name = item.value(forKey: "name") as? String {
                        locationNames.append(name)
                        locationIDs.append(id.uuidString)
                    }
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toLocationData" {
            let nextPage = segue.destination as! LocationData
            nextPage.incomingLocationID = selectedLocationID
        }
    }

    @IBAction func addLocationAction(_ sender: Any) {
        selectedLocationID = nil
        performSegue(withIdentifier: "toLocationData", sender: nil)
    }
    
}

extension LocationList: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locationNames.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        cell.textLabel?.text = locationNames[indexPath.row]
        return cell
    }
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedLocationID = locationIDs[indexPath.row]
        performSegue(withIdentifier: "toLocationData", sender: nil)
    }
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let delete = UIContextualAction(style: .destructive, title: "Delete"){ (contextualAction, view, boolValue) in
            let appDelegate = UIApplication.shared.delegate as! AppDelegate
            let context = appDelegate.persistentContainer.viewContext
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Locations")
            request.predicate = NSPredicate(format: "id = %@", self.locationIDs[indexPath.row])
            request.returnsObjectsAsFaults = false
            do {
                let result = try context.fetch(request) as! [NSManagedObject]
                for item in result {
                    context.delete(item)
                    self.locationNames.remove(at: indexPath.row)
                    self.locationIDs.remove(at: indexPath.row)
                    break
                }
            } catch {
                print(error.localizedDescription)
            }
            appDelegate.saveContext()
            tableView.reloadData()
        }
        let swipeAction = UISwipeActionsConfiguration(actions: [delete])
        return swipeAction
    }
}
