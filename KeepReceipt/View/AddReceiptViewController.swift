//
//  AddReceiptViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit

class AddReceiptViewController: UIViewController {
    
    var receiptImage: UIImage?
    
    // Switch status bar to white
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    // UI Stuff
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var vendorTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        if let image = receiptImage {
            receiptImageView.image = image
        }
        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        print("save button pressed")
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        print("cancel button pressed")
    }
    
    
    
}
