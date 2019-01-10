//
//  AddReceiptViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import Eureka
import SVProgressHUD
import SimpleImageViewer
import RealmSwift

class AddReceiptViewController: FormViewController {
    
    // Constants for all the form text/ID's
    let VENDOR_NAME_TAG = "vendorName"
    let VENDOR_NAME_TITLE = "Vendor Name"
    let VENDOR_NAME_PLACEHOLDER = "Enter the vendor name"
    let TXN_AMT_TAG = "txnAmount"
    let TXN_DATE_TAG = "txnDate"
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
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
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            receiptImageView.isUserInteractionEnabled = true
            receiptImageView.addGestureRecognizer(tapGestureRecognizer)
        }
        setUpForm()
        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        getEnteredValues()
        if validateOrShowError() {
            if let savedImage = ImageService.saveImage(for: receiptImage!) {
                
                print ("Image saved successfully")
                receiptImageView.image = ImageService.getImage(for: savedImage)!
                
            }
//            let newReciept = Receipt()
//            newReciept.vendor = statedVendor!
//            newReciept.amount = statedAmount!
//            newReciept.transactionTime = statedDate!
//            try! realm.write {
//                realm.add(newReciept)
//            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // TODO popup validation
        dismiss(animated: true, completion: nil)
    }
    
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer)
    {
        if let tappedImage = tapGestureRecognizer.view as? UIImageView {
            
            let imageViewerConfig = ImageViewerConfiguration { config in
                config.imageView = tappedImage
            }
            let imageViewerController = ImageViewerController(configuration: imageViewerConfig)
            present(imageViewerController, animated: true)
            
        }
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
        statedVendor = enteredValues[VENDOR_NAME_TAG] as! String?
        statedAmount = enteredValues[TXN_AMT_TAG] as! Double?
        statedDate = enteredValues[TXN_DATE_TAG] as! Date?
    }
    
    // Returns true if all fields are filled in
    private func validateOrShowError() -> Bool {
        // No need to check date because it will always be non-nil
        if statedVendor == nil || statedAmount == nil {
            SVProgressHUD.showError(withStatus: "Please fill out all fields")
            SVProgressHUD.dismiss(withDelay: TimeInterval(2))
            return false
        }
        return true
    }
    
}
