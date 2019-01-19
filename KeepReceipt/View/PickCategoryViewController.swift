//
//  PickCategoryViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-16.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import RealmSwift


// TODOS
// Have a "None" option (maybe) -> just set the canEditAtIndexPath property

class PickCategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var selectedCategory: Category?
    var allCategories: Results<Category>?
    
    // UI Stuff
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var addCategoryButton: UIBarButtonItem!
    @IBOutlet weak var deleteCategoryButton: UIBarButtonItem!
    @IBOutlet weak var cancelChooseButton: UIBarButtonItem!
    @IBOutlet weak var doneButton: UIBarButtonItem!
    override var preferredStatusBarStyle: UIStatusBarStyle {
        // Switch status bar to white
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set delegate and datasource
        tableView.delegate = self
        tableView.dataSource = self
        
        // Load all categories
        allCategories = realm.objects(Category.self)
        
    }
    
    // MARK: - Tableview methods
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return allCategories?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get a cell
        let cell = tableView.dequeueReusableCell(withIdentifier: "chooseCategoryCell")!
        
        // Else, retrieve the category that this cell should display
        let thisCategory = allCategories?[indexPath.row]
        cell.textLabel?.text = thisCategory?.name ?? ""
        
        // If this is the selected category, then add a checkmark
        if selectedCategory == thisCategory {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        
        return cell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Set selected category to new category, or nil on deselection
        if selectedCategory != allCategories?[indexPath.row] {
            selectedCategory = allCategories?[indexPath.row]
        } else {
            selectedCategory = nil
        }
        
        // Reload cells that have changed
        tableView.reloadData()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == UITableViewCell.EditingStyle.delete {
            // Find and delete the category
            let categoryToDelete = allCategories![indexPath.row]
            selectedCategory = selectedCategory == categoryToDelete ? nil : selectedCategory
            try! realm.write {
                realm.delete(allCategories![indexPath.row]) //TODO put in database service
            }
            // Disable editing if there are no categories
            if allCategories?.count == 0 {
                showEditingState(isEditing: false)
            }
            tableView.reloadData()
        }
    }
    
    
    // MARK: - Button Pressed Methods
    @IBAction func addCategoryButtonPressed(_ sender: UIBarButtonItem) {
        
        // Shows an alert with a textfield for new category
        let addCategoryAlert = UIAlertController(title: "Add New Category", message: "Specify a name for the category", preferredStyle: .alert)
        addCategoryAlert.addTextField(configurationHandler: nil)
        addCategoryAlert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            // Validate input
            let enteredText = addCategoryAlert.textFields![0].text!
            if self.validateCategoryName(for: enteredText) {
                // Create and save a new category
                let newCategory = Category()
                newCategory.name = enteredText
                try! self.realm.write {
                    self.realm.add(newCategory) // TODO put in database class
                }
                self.tableView.reloadData()
                // This is a bug where editing state is persisted if we delete all categories then create a new one
                if self.allCategories!.count == 1 {
                    self.showEditingState(isEditing: false)
                }
            }
        }))
        addCategoryAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        show(addCategoryAlert, sender: self)
    }
    
    @IBAction func deleteCategoryButtonPressed(_ sender: UIBarButtonItem) {
        // This just toggles is-editing state
        if tableView.isEditing {
            showEditingState(isEditing: false)
        } else {
            showEditingState(isEditing: true)
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        // Set selected category in previous view controller
        let parentVC = self.presentingViewController as! AddOrEditReceiptViewController
        parentVC.setSelectedCategory(category: selectedCategory) 
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Helper functions
    private func showEditingState(isEditing: Bool) {
        // isEditing indicates the DESIRED editing status
        if isEditing {
            tableView.setEditing(true, animated: true)
            // Delete Category -> "Done" to finish editing
            deleteCategoryButton.title = "Done"
            // Disable all the other buttons
            addCategoryButton.isEnabled = false
            doneButton.isEnabled = false
            cancelChooseButton.isEnabled = false
        } else {
            tableView.setEditing(false, animated: true)
            deleteCategoryButton.title = "Delete"
            // Enable all the other buttons
            addCategoryButton.isEnabled = true
            doneButton.isEnabled = true
            cancelChooseButton.isEnabled = true
            // Disable delete button if there is nothing to delete
            if allCategories!.count == 0 {
                deleteCategoryButton.isEnabled = false
            } else {
                deleteCategoryButton.isEnabled = true
            }
        }
    }
    
    // Returns true if validated, else will show error HUD
    private func validateCategoryName(for input: String) -> Bool {
        
        if input.isEmpty {
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Please enter a category name")
            return false
        } else if realm.objects(Category.self).filter("name == '\(input)'").count > 0 {
            UIService.showHUDWithNoAction(isSuccessful: false, with: "This category already exists")
            return false
        } else {
            return true
        }
    }

}
