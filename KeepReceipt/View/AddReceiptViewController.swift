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
    
    // Constants for all the form text/ID's
    let VENDOR_NAME_TAG = "vendorName"
    let VENDOR_NAME_TITLE = "Vendor Name"
    let VENDOR_NAME_PLACEHOLDER = "Enter the vendor name"
    let TXN_AMT_TAG = "txnAmount"
    let TXN_DATE_TAG = "txnDate"
    
    var receiptImage: UIImage?
    var statedVendor: String?
    var statedAmount: Double?
    var statedDate: Date?
    
    // UI Stuff
    @IBOutlet weak var receiptImageView: UIImageView!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // Switch status bar to white
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load image into view
        if let image = receiptImage {
            receiptImageView.image = image
        }
        setUpForm()
        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        print("save button pressed")
        getEnteredValues()
        // TODO validation
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // TODO popup validation
        print("cancel button pressed")
        dismiss(animated: true, completion: nil)
    }
    
    // Set up form using the Eureka library
    private func setUpForm() {
        
        // Enables smooth scrolling between form elements
        animateScroll = true
        
        // TODO replace all of these with constants
        form +++ Section("Receipt Details")
            <<< TextRow() { row in
                row.tag = VENDOR_NAME_TAG
                row.title = VENDOR_NAME_TITLE
                row.placeholder = VENDOR_NAME_PLACEHOLDER
            }
            <<< DecimalRow() { row in
                row.tag = TXN_AMT_TAG
                row.title = "Amount"
                row.placeholder = "Enter the transaction amount"
            }
            <<< DateRow(){ row in
                row.tag = TXN_DATE_TAG
                row.title = "Transaction Date"
                // Set to current date
                row.value = Date()
        }
    }
    
    // Loads values entered into form into the variables of this class
    private func getEnteredValues() {
        let enteredValues = form.values()
        print(enteredValues)
    }
    
}
