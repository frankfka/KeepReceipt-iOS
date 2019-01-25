//
//  AdvancedSearchViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-25.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import Eureka

class AdvancedSearchViewController: FormViewController {
    
    var statedCategory: Category?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First initialize form
        setUpForm()
        
    }
    
    // Set up form using the Eureka library
    private func setUpForm() {
        
        // Enables smooth scrolling between form elements
        animateScroll = true
        
        form
            +++ Section("General")
            <<< TextRow() { row in
                row.tag = Constants.VENDOR_NAME_TAG
                row.title = "Keywords"
                row.placeholder = "Vendor"
            }
            <<< MultipleSelectorRow<String>() { row in
                row.title = "Category" //2
                row.value = ["1"]
                row.options = ["1", "2", "3"]
                row.onChange { _ in
                    if let value = row.value {
                        // Assign selected value
                    }
                }
                row.onPresent { from, to in
                    to.selectableRowCellUpdate = { cell, row in
                        cell.tintColor = UIColor(named: "accent")
                    }
                }
            }
            
            +++ Section("Price")
            <<< DecimalRow() { row in
                row.tag = "112e"
                row.title = "Min Price"
                row.placeholder = Constants.TXN_AMT_PLACEHOLDER
            }
            <<< DecimalRow() { row in
                row.tag = "fsfd"
                row.title = "Max Price"
                row.placeholder = Constants.TXN_AMT_PLACEHOLDER
            }
            
            +++ Section("Date")
            <<< DateRow(){ row in
                row.tag = "sdfds"
                row.title = "From"
                // Set to current date
                row.value = Date()
            }
            <<< DateRow(){ row in
                row.tag = Constants.TXN_DATE_TAG
                row.title = "To"
                // Set to current date
                row.value = Date()
            }
        
    }
    
    // MARK: - Form input/validaton
    // Loads values entered into form into the variables of this class
//    private func getEnteredValues() {
//        let enteredValues = form.values()
//        statedVendor = enteredValues[Constants.VENDOR_NAME_TAG] as! String?
//        statedAmount = enteredValues[Constants.TXN_AMT_TAG] as! Double?
//        statedDate = enteredValues[Constants.TXN_DATE_TAG] as! Date?
//    }
    
    // Returns "None" if category is not selected, else returns category name
    private func getSelectedCategoryName() -> String {
        return statedCategory?.name ?? "None"
    }
    
    // Sets the selected category and updates UI, used by PickCategoryViewController
//    func setSelectedCategory(category: Category?) {
//        statedCategory = category
//        updateViews()
//    }
    
    // Returns true if all fields are filled in
//    private func validateFormFields() -> Bool {
        // No need to check date because it will always be non-nil
        // No need to check category because it is None by default
//        if statedVendor == nil || statedAmount == nil {
//            return false
//        }
//        return true
//    }

}
