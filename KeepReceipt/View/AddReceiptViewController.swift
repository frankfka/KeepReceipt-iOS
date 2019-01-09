//
//  AddReceiptViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import Eureka

class AddReceiptViewController: FormViewController {
    
    // Struct for form items tag constants
    struct FormItems {
        static let name = "name"
        static let birthDate = "birthDate"
        static let like = "like"
    }
    
    var receiptImage: UIImage?
    
    // Switch status bar to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // UI Stuff
    @IBOutlet weak var receiptImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = receiptImage {
            receiptImageView.image = image
        }
        
        form +++ Section("About You")
            <<< TextRow(FormItems.name) { row in
                row.title = "Name"
                row.placeholder = "Your Name"
            }
            <<< DateRow(FormItems.birthDate) { row in
                row.title = "Birthday"
            }
            <<< CheckRow(FormItems.like) { row in
                row.title = "I like Eureka"
                row.value = true
        }
        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        print("save button pressed")
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        print("cancel button pressed")
    }
    
    
    
}
