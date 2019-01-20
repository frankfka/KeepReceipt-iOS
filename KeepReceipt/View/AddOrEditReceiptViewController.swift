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

class AddOrEditReceiptViewController: FormViewController {
    
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
    private let CATEGORY_TAG = "category"
    private let CATEGORY_TITLE = "Category"
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    
    // ADDING RECEIPT
    var receiptToAddImage: UIImage?
    // EDITING RECEIPT
    var receiptToEdit: Receipt?
    var previousCategory: Category?
    
    // States from fields
    var statedVendor: String?
    var statedAmount: Double?
    var statedDate: Date?
    var statedCategory: Category?
    
    // UI Variables
    @IBOutlet weak var receiptImageView: UIImageView!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // Switch status bar to white
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Create form elements
        setUpForm()
        
        // Check if we're adding or editing a receipt
        if let image = receiptToAddImage {
            title = "Add Receipt"
            receiptImageView.image = image
        } else if let receipt = receiptToEdit {
            title = "Edit Receipt"
            // Populate all the form elements
            receiptImageView.image = ImageService.getImage(for: receipt.receiptId!)
            // Set existing values and update views to match
            setExistingValues()
            updateViews()
        } else {
            // This is an error case, should never happen, dismiss to prevent further problems
            print("AddOrEditViewController initialized without an image or a receipt")
            dismiss(animated: true, completion: nil)
        }
        
        // Add a recognizer to the ImageView so we can expand it on tap
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        receiptImageView.isUserInteractionEnabled = true
        receiptImageView.addGestureRecognizer(tapGestureRecognizer)
        
    }
    
    // This handles the case for when the old category has been deleted
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let prevCategory = previousCategory {
            if prevCategory.isInvalidated {
                // Just set previous category to "None"
                previousCategory = nil
            }
        }
    }
    

    // Updates view
    private func updateViews() {
        form.setValues([CATEGORY_TAG: getSelectedCategoryName()])
        if let receipt = receiptToEdit {
            form.setValues([VENDOR_NAME_TAG: receipt.vendor, TXN_AMT_TAG: receipt.amount, TXN_DATE_TAG: receipt.transactionTime])
        }
    }
    
    // MARK: - Button Pressed Methods
    @IBAction func saveButtonPressed(_ sender: UIBarButtonItem) {
        
        // Load the entered values within the form & validate
        getEnteredValues()
        if validateFormFields() {
            
            // Case where we're adding a new receipt
            if let receiptImage = receiptToAddImage {
                
                if let savedImageId = ImageService.saveImageAndGetId(for: receiptImage) {
                    
                    // Create a new receipt with the stuff in the fields
                    let newReceipt = Receipt()
                    newReceipt.receiptId = savedImageId
                    newReceipt.vendor = statedVendor!
                    newReceipt.amount = statedAmount!
                    newReceipt.transactionTime = statedDate!
                    DatabaseService.save(newReceipt)
                    // Save the receipt, then we can add it to a category if one is specified
                    if let category = statedCategory {
                        DatabaseService.updateCategory(for: newReceipt, from: nil, to: category)
                    }
                    
                    // Dismiss VC and show success
                    UIService.showHUDWithNoAction(isSuccessful: true, with: "Receipt Saved")
                    dismiss(animated: true, completion: nil)
                    
                } else {
                    UIService.showHUDWithNoAction(isSuccessful: false, with: "Something went wrong, please try again")
                }
                
            // Case where we're updating a receipt
            } else if let receipt = receiptToEdit {
                
                // Update stuff, these methods will handle all the logic
                DatabaseService.updateReceipt(receipt, newVendor: statedVendor!, newAmount: statedAmount!, newDate: statedDate!)
                DatabaseService.updateCategory(for: receipt, from: previousCategory, to: statedCategory)
                
                // Dismiss VC and show success
                UIService.showHUDWithNoAction(isSuccessful: true, with: "Changes Saved")
                dismiss(animated: true, completion: nil)
            }
            
        } else {
            // Show error prompt - happens when form is not validated
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Please fill out all fields")
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        // Display popup validation & handle accordingly
        let confirmCancelController = UIAlertController(title: receiptToAddImage == nil ? "Cancel Edit Receipt" : "Cancel Add Receipt", message: "Are you sure you want to cancel?" , preferredStyle: .alert)
        confirmCancelController.addAction(UIAlertAction(title: "Yes", style: .destructive, handler: { (action) in
            self.dismiss(animated: true, completion: nil)
        }))
        confirmCancelController.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        
        show(confirmCancelController, sender: self)
    }
    
    // MARK: - Image/Form Methods
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
                row.displayValueFor = {
                    // TODO this does not work on overwrite
                    return $0.map { "$" + String(describing: $0) }
                }
            }
            <<< DateRow(){ row in
                row.tag = TXN_DATE_TAG
                row.title = TXN_DATE_TITLE
                // Set to current date
                row.value = Date()
            }
            <<< TextRow(){ row in
                row.tag = CATEGORY_TAG
                row.title = CATEGORY_TITLE
                row.value = self.getSelectedCategoryName()
                row.cell.textField.isUserInteractionEnabled = false
                }.onCellSelection { cell, row in
                    // When selected, we show the pick category segue
                    self.performSegue(withIdentifier: "PickCategoryForReceiptSegue", sender: self)
                }
    }
    
    // MARK: - Form input/validaton
    // Loads values entered into form into the variables of this class
    private func getEnteredValues() {
        let enteredValues = form.values()
        statedVendor = enteredValues[VENDOR_NAME_TAG] as! String?
        statedAmount = enteredValues[TXN_AMT_TAG] as! Double?
        statedDate = enteredValues[TXN_DATE_TAG] as! Date?
    }
    
    // Loads current receipt values into the form
    private func setExistingValues() {
        if let receipt = receiptToEdit {
            // Initialize selected category
            if receipt.categories.count != 0 {
                // Only one category can be chosen for now
                statedCategory = receipt.categories[0]
                previousCategory = receipt.categories[0]
            }
        }
    }
    
    // Returns true if all fields are filled in
    private func validateFormFields() -> Bool {
        // No need to check date because it will always be non-nil
        // No need to check category because it is None by default
        if statedVendor == nil || statedAmount == nil {
            return false
        }
        return true
    }
    
    // MARK: - Misc Methods
    // This initializes PickCategoryViewController to show the current selected category
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategoryForReceiptSegue" {
            let destinationVC = segue.destination as! PickCategoryViewController
            destinationVC.selectedCategory = statedCategory
        }
    }
    
    // Returns "None" if category is not selected, else returns category name
    private func getSelectedCategoryName() -> String {
        return statedCategory?.name ?? "None"
    }
    
    // Sets the selected category and updates UI, used by PickCategoryViewController
    func setSelectedCategory(category: Category?) {
        statedCategory = category
        updateViews()
    }
    
}
