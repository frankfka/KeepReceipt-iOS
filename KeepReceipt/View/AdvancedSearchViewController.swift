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
    
    // For the search results
    var searchResults: Results<Receipt>?

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
                    
                    // Get entered values then validate
                    self.getEnteredValues()
                    if self.validateFormFields() {
                        
                        // Create query from fields
                        if let query = self.getQuery() {
                            // Query is valid, we proceed
                            self.searchResults = self.realm.objects(Receipt.self).filter(query).sorted(byKeyPath: "transactionTime", ascending: false)
                            
                            // If search results is empty, just show an error instead
                            if !self.searchResults!.isEmpty {
                                self.performSegue(withIdentifier: "AdvancedSearchToResultsSegue", sender: self)
                            } else {
                                UIService.showHUDWithNoAction(isSuccessful: false, with: "No results found")
                            }
                            
                        } else {
                            // Just show all the receipts
                            self.searchResults = self.realm.objects(Receipt.self).sorted(byKeyPath: "transactionTime", ascending: false)
                            self.performSegue(withIdentifier: "AdvancedSearchToResultsSegue", sender: self)
                        }
                    }
                }
        }
    }
    
    // Initialize destination
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // There should be a receipt specified
        let destinationVC = segue.destination as! SearchResultsTableViewController
        destinationVC.receiptsToShow = searchResults
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
    
    // Validates that max > min for entered fields, returns true if we can go ahead with the query
    // Will also display HUD for various errors
    private func validateFormFields() -> Bool {
        
        if maxPrice != nil && minPrice != nil && maxPrice! < minPrice! {
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Please specify a correct price range")
            return false
        }
        
        if maxDate != nil && minDate != nil && maxDate! < minDate! {
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Please specify a correct date range")
            return false
        }
        
        return true
    }
    
    // MARK: - Constructs a query
    private func getQuery() -> NSCompoundPredicate? {
        
        var query: [NSPredicate] = []
        
        if let statedKeyword = keywords {
            query.append(NSPredicate(format: "vendor CONTAINS[cd] '\(statedKeyword)'"))
        }
        if selectedCategoryNames != nil && !selectedCategoryNames!.isEmpty {
            
            // Loop through all the selected categories & append by OR
            var categorySubPredicates: [NSPredicate] = []
            for categoryName in selectedCategoryNames! {
                categorySubPredicates.append(NSPredicate(format: "ANY categories.name == '\(categoryName)'"))
            }
            query.append(NSCompoundPredicate(orPredicateWithSubpredicates: categorySubPredicates))
            
        }
        if let statedMinPrice = minPrice {
            query.append(NSPredicate(format: "amount >= \(statedMinPrice)"))
        }
        if let statedMaxPrice = maxPrice {
            query.append(NSPredicate(format: "amount <= \(statedMaxPrice)"))
        }
        if let statedMinDate = minDate {
            // Decrement by a day so that receipts added on the specified date is shown
            query.append(NSPredicate(format: "transactionTime >= %@", NSDate(timeInterval: -86400, since: statedMinDate)))
        }
        if let statedMaxDate = maxDate {
            // Increment by a day so that receipts added on the specified date is shown
            query.append(NSPredicate(format: "transactionTime <= %@", NSDate(timeInterval: 86400, since: statedMaxDate)))
        }
        
        // Return query if conditions are specified, otherwise return nil
        if !query.isEmpty {
            let query = NSCompoundPredicate(andPredicateWithSubpredicates: query)
            return query
        }
        return nil
    }

}
