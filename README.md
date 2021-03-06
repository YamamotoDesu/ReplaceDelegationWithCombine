# Replace Delegation With Combine 
How to implement a common iOS design pattern, delegation, using Combine’s publishers and subscribers.   
We will compare the standard delegation approach with one using Combine.

## Getting Started 
<table border="0">
    <tr>
        <td><img src="https://user-images.githubusercontent.com/47273077/133958788-02d3da18-829d-4185-994b-9fd7d1eca382.png" width="200"></td>
        <td><img src="https://user-images.githubusercontent.com/47273077/133958828-2cca054f-b23a-4799-9776-1572052135e7.png" width="200"></td>
    </tr>
</table>

### Traditional Approach 
#### **[ItemsViewController](https://github.com/YamamotoDesu/Replace-Delegation-With-Combine/blob/main/CombineSample/ItemsViewController.swift)**  
```swift 
import UIKit

class ItemsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addItemViewController = storyBoard.instantiateViewController(withIdentifier: "addItemViewController") as! AddItemViewController
        addItemViewController.delegate = self
        
        self.present(addItemViewController, animated: true, completion: nil)
    }

    var items: [String] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
}

extension ItemsViewController: AddItemViewControllerDelegate {
    func didAddItem(_ item: String) {
        self.items.append(item)
        self.tableView.beginUpdates()
        self.tableView.insertRows(
            at: [
                .init(row: items.count - 1,
                      section: 0)
            ],
            with: .automatic
        )
        self.tableView.endUpdates()
    }
}

extension ItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

``` 

#### **[AddItemViewController](https://github.com/YamamotoDesu/Replace-Delegation-With-Combine/blob/main/CombineSample/AddItemViewController.swift)**  
```swift 
import UIKit

protocol AddItemViewControllerDelegate: AnyObject {
    func didAddItem(_ item: String)
}

class AddItemViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    weak var delegate: AddItemViewControllerDelegate?
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        delegate?.didAddItem(textField.text!)
        self.dismiss(animated: true, completion: nil)
    }
    
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    
}


```

### Using Combine 
#### **[AddItemViewController](https://github.com/YamamotoDesu/Replace-Delegation-With-Combine/blob/main/CombineSample/AddItemViewController.swift)**  
```swift 
import UIKit

class AddItemViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        newItem.send(textField.text!)
        self.dismiss(animated: true, completion: nil)
    }
    
    let newItem = PassthroughSubject<String, Never>()
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
}


```

#### **[ItemsViewController](https://github.com/YamamotoDesu/Replace-Delegation-With-Combine/blob/main/CombineSample/ItemsViewController.swift)**  
```swift 
import UIKit

class ItemsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addItemViewController = storyBoard.instantiateViewController(withIdentifier: "addItemViewController") as! AddItemViewController
        
        addItemViewController.newItem
            .handleEvents(receiveOutput: { [unowned self] newItem in
                self.updateTableView(withItem: newItem)
            })
            .sink { _ in }
            .store(in: &subscriptions)
        
        self.present(addItemViewController, animated: true, completion: nil)
    }
    
    func updateTableView(withItem item: String) {
        self.items.append(item)
        self.tableView.beginUpdates()
        self.tableView.insertRows(
            at: [
                .init(row: self.items.count - 1,
                      section: 0)
            ],
            with: .automatic
        )
        self.tableView.endUpdates()
    }

    var subscriptions = Set<AnyCancellable>()
    var items: [String] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
}

extension ItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

``` 

### Refactoring: Store the publisher in a struct as a static variable   
This way other pieces of your project could also get notified of new items.

#### **[AddItemViewController](https://github.com/YamamotoDesu/Replace-Delegation-With-Combine/blob/main/CombineSample/AddItemViewController.swift)**  
```swift 
struct NewItem {
    static var newItem
    = PassthroughSubject<String, Never>()
}

class AddItemViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        NewItem.newItem.send(textField.text!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    
}
```

#### **[ItemsViewController](https://github.com/YamamotoDesu/Replace-Delegation-With-Combine/blob/main/CombineSample/ItemsViewController.swift)**  
```swift 
import UIKit

class ItemsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func addButtonTapped(_ sender: UIButton) {
        let storyBoard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
        let addItemViewController = storyBoard.instantiateViewController(withIdentifier: "addItemViewController") as! AddItemViewController
        
        NewItem.newItem
            .handleEvents(receiveOutput: { [unowned self] newItem in
                self.updateTableView(withItem: newItem)
            })
            .sink { _ in }
            .store(in: &subscriptions)
        
        self.present(addItemViewController, animated: true, completion: nil)
    }
    
    func updateTableView(withItem item: String) {
        self.items.append(item)
        self.tableView.beginUpdates()
        self.tableView.insertRows(
            at: [
                .init(row: self.items.count - 1,
                      section: 0)
            ],
            with: .automatic
        )
        self.tableView.endUpdates()
    }

    var subscriptions = Set<AnyCancellable>()
    var items: [String] = []
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addButton: UIButton!
}

extension ItemsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell")!
        cell.textLabel?.text = items[indexPath.row]
        return cell
    }
}

``` 



