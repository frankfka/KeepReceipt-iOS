//
//  AddReceiptViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import Eureka
import SimpleImageViewer
import RealmSwift

class AddReceiptViewController: FormViewController {
    
    // Constants for all the form text/ID's
    private let SECTION_TITLE = "Receipt Details"
    private let VENDOR_NAME_TAG = "vendorName"
    private let VENDOR_NAME_TITLE = "Vendor Name"
    private let VENDOR_NAME_PLACEHOLDER = "Enter the vendor name"
    private let TXN_AMT_TAG = "txnAmount"
    private let TXN_AMT_TITLE = "Amount"
    private let TXN_AMT_PLACEHOLDER = "Enter the transaction amount"
    private let TXN_DATE_TAG = "txnDate"
    private let TXN_DATE_TITLE = "Transaction Date"
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var receiptImage: UIImage?
    var statedVendor: String?
    var statedAmount: Double?
    var statedDate: Date?
    
    // UI Variables
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
            
            // Add a recognizer to the ImageView so we can expand it on tap
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
            receiptImageView.isUserInteractionEnabled = true
            receiptImageView.addGestureRecognizer(tapGestureRecognizer)
        }
        
        // Create form elements
        setUpForm()
        
    }
    
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        // Load the entered values within the form & validate
        getEnteredValues()
        if validateFormFields() {
            if let savedImageId = ImageService.saveImageAndGetId(for: receiptImage!) {
                
                receiptImageView.image = ImageService.getImage(for: savedImageId)!
                let newReceipt = Receipt()
                newReceipt.receiptId = savedImageId
                newReceipt.vendor = statedVendor!
                newReceipt.amount = statedAmount!
                newReceipt.transactionTime = statedDate!
                try! realm.write {
                    realm.add(newReceipt)
                }
                
                // Dismiss VC and show success
                UIService.showHUDWithNoAction(isSuccessful: true, with: "Receipt Saved")
                dismiss(animated: true, completion: nil)
                
            } else {
                UIService.showHUDWithNoAction(isSuccessful: false, with: "Something went wrong, please try again")
            }
        } else {
            // Show error prompt
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Please fill out all fields")
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // TODO popup validation
        dismiss(animated: true, completion: nil)
    }
    
    // We use the SimpleImageViewer library to show an activity with fullscreen image
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        
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
        
        form +++ Section(SECTION_TITLE)
            <<< TextRow() { row in
                row.tag = VENDOR_NAME_TAG
                row.title = VENDOR_NAME_TITLE
                row.placeholder = VENDOR_NAME_PLACEHOLDER
            }
            <<< DecimalRow() { row in
                row.tag = TXN_AMT_TAG
                row.title = TXN_AMT_TITLE
                row.placeholder = TXN_AMT_PLACEHOLDER
            }
            <<< DateRow(){ row in
                row.tag = TXN_DATE_TAG
                row.title = TXN_DATE_TITLE
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
    private func validateFormFields() -> Bool {
        // No need to check date because it will always be non-nil
        if statedVendor == nil || statedAmount == nil {
            return false
        }
        return true
    }
    
}
