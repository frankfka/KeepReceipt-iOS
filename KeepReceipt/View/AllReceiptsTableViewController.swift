//
//  AllReceiptsTableViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import RealmSwift
import EmptyDataSet_Swift

class AllReceiptsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UISearchBarDelegate {
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var allReceipts: Results<Receipt>?
    // Displayed may not be all in the case that a search is entered
    var displayedReceipts: Results<Receipt>?
    var selectedReceipt: Receipt?
    @IBOutlet weak var searchBar: UISearchBar!
    
    // For the add button
    var receiptImageToAdd: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the data
        getAllReceipts()
        
        // Initialize search
        searchBar.delegate = self
        
        // Register custom tableview cell
        tableView.register(UINib(nibName: "ReceiptTableViewCell", bundle: nil), forCellReuseIdentifier: "ReceiptTableViewCell")
        
        // Empty dataset
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
    }
    
    func getAllReceipts() {
        allReceipts = realm.objects(Receipt.self).sorted(byKeyPath: "transactionTime", ascending: false)
        displayedReceipts = realm.objects(Receipt.self).sorted(byKeyPath: "transactionTime", ascending: false)
    }
    
    // Reload tableview every time we return to this VC
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedReceipts?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiptTableViewCell") as! ReceiptTableViewCell
        // Don't do anything if the receipt is somehow nil
        if let receipt = displayedReceipts?[indexPath.row] {
            cell.initializeUI(for: receipt)
        }
        return cell
        
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // If we have multiple tables, will need to check the table but we can ignore that for now
        selectedReceipt = displayedReceipts![indexPath.row]
        performSegue(withIdentifier: "ReceiptListToReceiptSegue", sender: self)
    }

    // Called when the add receipt button is tapped
    @IBAction func addNewReceiptPressed(_ sender: UIBarButtonItem) {
        
        // Alert controller to ask whether we want to import or take a photo
        let addReceiptAlert = UIAlertController(title: "Add New Receipt", message: "Take a new photo or import an existing image", preferredStyle: .alert)
        // Case where user wants to take a photo
        addReceiptAlert.addAction(UIAlertAction(title: "Take Photo", style: .default, handler: { (action) in
            if UIImagePickerController.isSourceTypeAvailable(.camera) {
                let takeImageVC = UIImagePickerController()
                takeImageVC.sourceType = .camera
                takeImageVC.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
                self.present(takeImageVC, animated: true)
            }
            else {
                UIService.showHUDWithNoAction(isSuccessful: false, with: "No camera available")
            }
        }))
        // Case where user wants to import a photo
        addReceiptAlert.addAction(UIAlertAction(title: "Import from Photos", style: .default, handler: { (action) in
            let importImageVC = UIImagePickerController()
            importImageVC.sourceType = .photoLibrary
            importImageVC.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            importImageVC.navigationBar.barStyle = .default
            self.present(importImageVC, animated: true)
        }))
        // Cancel
        addReceiptAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(addReceiptAlert, animated: true, completion: nil)
        
        
    }
    
    
    // Used to start a new activity to take an image
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        let pickedImage = info[.originalImage] as? UIImage
        picker.dismiss(animated: true, completion: nil)
        
        if let image = pickedImage {
            // Start the view controller to add the receipt
            receiptImageToAdd = image
            performSegue(withIdentifier: "AllReceiptsToAddReceipt", sender: self)
        } else {
            print("No photo was selected")
        }
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AllReceiptsToAddReceipt" {
            let destinationVC = segue.destination as! AddOrEditReceiptViewController
            destinationVC.receiptToAddImage = receiptImageToAdd
        } else if segue.identifier == "ReceiptListToReceiptSegue" {
            // There should be a receipt specified
            let destinationVC = segue.destination as! ViewReceiptViewController
            destinationVC.receipt = selectedReceipt
        }
        // Else do nothing
    }
    
    //MARK: - Search bar methods
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.count > 0 {
            var filteredReceipts = allReceipts!.filter("vendor CONTAINS[cd] '\(searchText)'")
            if let amount = Double(string: searchText) {
                // number entered, try searching in amount as well
                filteredReceipts = filteredReceipts.filter("amount == \(amount)")
            }
            displayedReceipts = filteredReceipts.sorted(byKeyPath: "transactionTime", ascending: false)
            tableView.reloadData()
        } else {
            getAllReceipts()
            tableView.reloadData()
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(true, animated: true)
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchBar.setShowsCancelButton(false, animated: true)
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.text = ""
        getAllReceipts()
        tableView.reloadData()
        searchBar.resignFirstResponder()
    }
    
}

// Extension for empty dataset methods
extension AllReceiptsTableViewController: EmptyDataSetSource, EmptyDataSetDelegate {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "No Receipts Found")
    }
    
    func description(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "Tap '+' to add a new receipt.")
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return UIImage(named: "emptyPlaceholder")
    }
    
    func backgroundColor(forEmptyDataSet scrollView: UIScrollView) -> UIColor? {
        return UIColor(named: "FFFFFF")
    }
    
    func emptyDataSetWillAppear(_ scrollView: UIScrollView) {
        tableView.separatorStyle = .none
    }
 
    func emptyDataSetWillDisappear(_ scrollView: UIScrollView) {
        tableView.separatorStyle = .singleLine
    }
    
}
