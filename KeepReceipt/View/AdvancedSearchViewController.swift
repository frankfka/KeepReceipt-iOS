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
    
    @IBAction func resetButtonPressed(_ sender: UIBarButtonItem) {
        
        // Reset all the fields
        keywordsRow?.value = nil
        categoryRow?.value = nil
        minPriceRow?.value = nil
        maxPriceRow?.value = nil
        minDateRow?.value = nil
        maxDateRow?.value = nil
        
        // Reload form
        keywordsRow?.reload()
        categoryRow?.reload()
        minPriceRow?.reload()
        maxPriceRow?.reload()
        minDateRow?.reload()
        maxDateRow?.reload()
        
        // Reload state variables
        getEnteredValues()
        
    }
    
    // MARK: - Form helper functions
    
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
                    self.getQueryString()
                }
        }
        
    }
    
    // Loads values entered into form into the variables of this class
    private func getEnteredValues() {
        let enteredValues = form.values()
        keywords = enteredValues[Constants.RECEIPT_SEARCH_KEYWORDS_TAG] as! String?
        minPrice = enteredValues[Constants.RECEIPT_SEARCH_PRICE_MIN_TAG] as! Double?
        maxPrice = enteredValues[Constants.RECEIPT_SEARCH_PRICE_MAX_TAG] as! Double?
        minDate = enteredValues[Constants.RECEIPT_SEARCH_DATE_MIN_TAG] as! Date?
        maxDate = enteredValues[Constants.RECEIPT_SEARCH_DATE_MAX_TAG] as! Date?
        selectedCategoryNames = enteredValues[Constants.RECEIPT_SEARCH_CATEGORY_TAG] as! Set<String>?
    }
    
    // Retrieves all categories from realm and puts them into an array of category names
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
    
    // MARK: - Creates a filter string for search function
    private func getQueryString() -> String {
        var query = ""
        if let statedKeyword = keywords {
            query = query + " AND (vendor CONTAINS[cd] '\(statedKeyword)')"
        }
        if selectedCategoryNames != nil && !selectedCategoryNames!.isEmpty {
            
            let statedCategories = selectedCategoryNames!
            // This needs to be filtered another way
            var categoryFilterString = ""
            for categoryName in statedCategories {
                categoryFilterString = categoryFilterString + " OR (ANY categories.name == '\(categoryName)')"
            }
            if !categoryFilterString.isEmpty {
                categoryFilterString = String(categoryFilterString.dropFirst(4))
            }
            query = query + " AND (\(categoryFilterString))"
            
        }
        if let statedMinPrice = minPrice {
            query = query + " AND (amount >= \(statedMinPrice))"
        }
        if let statedMaxPrice = maxPrice {
            query = query + " AND (amount <= \(statedMaxPrice))"
        }
        if let statedMinDate = minDate {
            query = query + " AND (transactionTime >= \(statedMinDate))"
        }
        if let statedMaxDate = maxDate {
            query = query + " AND (transactionTime <= \(statedMaxDate))"
        }
        
        // If query is not empty, trip the first AND
        if !query.isEmpty {
            query = String(query.dropFirst(5))
        }
        
        print(query)
        if (!query.isEmpty) {
            print(realm.objects(Receipt.self).filter(query))
            
        }
        return query
    }

}
