//
//  AddItemViewController.swift
//  CombineSample
//
//  Created by 山本響 on 2021/09/20.
//

import UIKit
import Combine

protocol AddItemViewControllerDelegate: AnyObject {
    func didAddItem(_ item: String)
}

struct NewItem {
    static var newItem
    = PassthroughSubject<String, Never>()
}

class AddItemViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
//    weak var delegate: AddItemViewControllerDelegate?
//
//    @IBAction func doneButtonTapped(_ sender: UIButton) {
//        delegate?.didAddItem(textField.text!)
//        self.dismiss(animated: true, completion: nil)
//    }
    
    @IBAction func doneButtonTapped(_ sender: UIButton) {
        NewItem.newItem.send(textField.text!)
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var doneButton: UIButton!
    
    
}
