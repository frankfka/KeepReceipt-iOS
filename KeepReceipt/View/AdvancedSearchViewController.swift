//
//  AdvancedSearchViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-25.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import Eureka
import RealmSwift

class AdvancedSearchViewController: FormViewController {
    
    let realm = try! Realm()
    
    // State variables
    var keywords: String?
    var selectedCategoryNames: Set<String>?
    var minPrice: Double?
    var maxPrice: Double?
    var minDate: Date?
    var maxDate: Date?
    var allCategoriesForm: [String] = []
    var allCategoriesRealm: Results<Category>?
    
    // Form rows
    var keywordsRow: TextRow?
    var categoryRow: MultipleSelectorRow<String>?
    var minPriceRow: DecimalRow?
    var maxPriceRow: DecimalRow?
    var minDateRow: DateRow?
    var maxDateRow: DateRow?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // First initialize form
        setUpForm()
        
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refreshes all categories in case one has been added
        updateAllCategories()
    }
    
    // Set up form using the Eureka library
    private func setUpForm() {
        
        // Enables smooth scrolling between form elements
        animateScroll = true
        
        // Get the categories as a set of strings if the set doesn't exist (on initial load)
        updateAllCategories()
        
        // This creates all the form elements, and assigns the row variables on creation
        form
            +++ Section(Constants.RECEIPT_SEARCH_SECTION_GENERAL_TITLE)
            <<< TextRow() { row in
                row.tag = Constants.RECEIPT_SEARCH_KEYWORDS_TAG
                row.title = Constants.RECEIPT_SEARCH_KEYWORDS_TITLE
                row.placeholder = Constants.RECEIPT_SEARCH_ANY_PLACEHOLDER
                self.keywordsRow = row
            }
            <<< MultipleSelectorRow<String>() { row in
                row.title = Constants.RECEIPT_SEARCH_CATEGORY_TITLE
                row.options = allCategoriesForm // This needs to be initialized at this point
                row.tag = Constants.RECEIPT_SEARCH_CATEGORY_TAG
                row.noValueDisplayText = Constants.RECEIPT_SEARCH_ANY_PLACEHOLDER
                row.onPresent { from, to in
                    to.selectableRowCellUpdate = { cell, row in
                        cell.tintColor = UIColor(named: "accent")
                    }
                }
                self.categoryRow = row
            }
            
            +++ Section(Constants.RECEIPT_SEARCH_SECTION_PRICE_TITLE)
            <<< DecimalRow() { row in
                row.tag = Constants.RECEIPT_SEARCH_PRICE_MIN_TAG
                row.title = Constants.RECEIPT_SEARCH_PRICE_MIN_TITLE
                row.placeholder = Constants.RECEIPT_SEARCH_ANY_PLACEHOLDER
                self.minPriceRow = row
            }
            <<< DecimalRow() { row in
                row.tag = Constants.RECEIPT_SEARCH_PRICE_MAX_TAG
                row.title = Constants.RECEIPT_SEARCH_PRICE_MAX_TITLE
                row.placeholder = Constants.RECEIPT_SEARCH_ANY_PLACEHOLDER
                self.maxPriceRow = row
            }
            
            +++ Section(Constants.RECEIPT_SEARCH_SECTION_DATE_TITLE)
            <<< DateRow() { row in
                row.tag = Constants.RECEIPT_SEARCH_DATE_MIN_TAG
                row.title = Constants.RECEIPT_SEARCH_DATE_MIN_TITLE
                row.noValueDisplayText = Constants.RECEIPT_SEARCH_ANY_PLACEHOLDER
                self.minDateRow = row
            }
            <<< DateRow() { row in
                row.tag = Constants.RECEIPT_SEARCH_DATE_MAX_TAG
                row.title = Constants.RECEIPT_SEARCH_DATE_MAX_TITLE
                row.noValueDisplayText = Constants.RECEIPT_SEARCH_ANY_PLACEHOLDER
                self.maxDateRow = row
            }
        
            +++ Section()
            <<< ButtonRow() { row in
                row.title = Constants.RECEIPT_SEARCH_BUTTON_TITLE
                row.onCellSelection { row, cell in
                    self.getEnteredValues()
                }
            }
        
    }
    
    // MARK: - Form input/validaton
    // Loads values entered into form into the variables of this class
    private func getEnteredValues() {
        let enteredValues = form.values()
        keywords = enteredValues[Constants.RECEIPT_SEARCH_KEYWORDS_TAG] as! String?
        minPrice = enteredValues[Constants.RECEIPT_SEARCH_PRICE_MIN_TAG] as! Double?
        maxPrice = enteredValues[Constants.RECEIPT_SEARCH_PRICE_MAX_TAG] as! Double?
        minDate = enteredValues[Constants.RECEIPT_SEARCH_DATE_MIN_TAG] as! Date?
        maxDate = enteredValues[Constants.RECEIPT_SEARCH_DATE_MAX_TAG] as! Date?

    }
    
    private func updateAllCategories() {
        
        // Get categories if not yet initialized
        if allCategoriesRealm == nil {
            allCategoriesRealm = realm.objects(Category.self)
        }
        
        // Create new list
        allCategoriesForm = []
        // First convert all the realm values to a set
        for category in allCategoriesRealm! {
            allCategoriesForm.append(category.name!)
        }
        
        // Now update the form if the rows have been set up
        if let categoriesRow = categoryRow {
            categoriesRow.options = allCategoriesForm
            categoriesRow.reload()
        }
    }
    
    // Returns "None" if category is not selected, else returns category name
//    private func getSelectedCategoryName() -> String {
//        return statedCategory?.name ?? "None"
//    }
    
    // Sets the selected category and updates UI, used by PickCategoryViewController
//    func setSelectedCategory(category: Category?) {
//        statedCategory = category
//        updateViews()
//    }

}
