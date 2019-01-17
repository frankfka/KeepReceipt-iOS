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
// Set the property in the incoming view controller
// Document this class

class PickCategoryViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var selectedCategory: Category?
    var allCategories: Results<Category>?
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
            let categoryToDelete = allCategories![indexPath.row]
            selectedCategory = selectedCategory == categoryToDelete ? nil : selectedCategory
            try! realm.write {
                realm.delete(allCategories![indexPath.row])
            }
            if allCategories?.count == 0 {
                showEditingState(isEditing: false)
            }
            tableView.reloadData()
        }
    }
    
    
    // MARK: - Button Pressed Methods
    @IBAction func addCategoryButtonPressed(_ sender: UIBarButtonItem) {
        let addCategoryAlert = UIAlertController(title: "Add New Category", message: "Specify a name for the category", preferredStyle: .alert)
        addCategoryAlert.addTextField(configurationHandler: nil)
        addCategoryAlert.addAction(UIAlertAction(title: "Save", style: .default, handler: { (action) in
            let enteredText = addCategoryAlert.textFields![0].text!
            if enteredText.isEmpty {
                UIService.showHUDWithNoAction(isSuccessful: false, with: "Please enter a category name")
            } else {
                let newCategory = Category()
                newCategory.name = enteredText
                try! self.realm.write {
                    self.realm.add(newCategory)
                }
                self.tableView.reloadData()
                if self.allCategories!.count == 1 {
                    self.showEditingState(isEditing: false)
                }
            }
        }))
        addCategoryAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        show(addCategoryAlert, sender: self)
    }
    
    @IBAction func deleteCategoryButtonPressed(_ sender: UIBarButtonItem) {
        if tableView.isEditing {
            showEditingState(isEditing: false)
        } else {
            showEditingState(isEditing: true)
        }
    }
    
    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true, completion: nil)
    }
    
    private func showEditingState(isEditing: Bool) {
        if isEditing {
            tableView.setEditing(true, animated: true)
            deleteCategoryButton.title = "Done"
            addCategoryButton.isEnabled = false
            doneButton.isEnabled = false
            cancelChooseButton.isEnabled = false
        } else {
            tableView.setEditing(false, animated: true)
            deleteCategoryButton.title = "Delete"
            addCategoryButton.isEnabled = true
            doneButton.isEnabled = true
            cancelChooseButton.isEnabled = true
            if allCategories!.count == 0 {
                deleteCategoryButton.isEnabled = false
            } else {
                deleteCategoryButton.isEnabled = true
            }
        }
    }

}
