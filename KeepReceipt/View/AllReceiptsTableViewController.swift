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

class AllReceiptsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var allReceipts: Results<Receipt>?
    // Displayed may not be all in the case that a search is entered
    var displayedReceipts: Results<Receipt>?
    var selectedReceipt: Receipt?
    
    // For the add button
    var receiptImageToAdd: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the data
        allReceipts = realm.objects(Receipt.self).sorted(byKeyPath: "transactionTime", ascending: false)
        displayedReceipts = realm.objects(Receipt.self).sorted(byKeyPath: "transactionTime", ascending: false)

        // Register custom tableview cell
        tableView.register(UINib(nibName: "ReceiptTableViewCell", bundle: nil), forCellReuseIdentifier: "ReceiptTableViewCell")
        tableView.separatorStyle = .none
        
        // Empty dataset stuff
        tableView.emptyDataSetSource = self
        tableView.emptyDataSetDelegate = self
        
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
        
        // Get an unused cell - TODO use a formatted cell instead
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

    @IBAction func addNewReceiptPressed(_ sender: UIBarButtonItem) {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let takeImageVC = UIImagePickerController()
            takeImageVC.sourceType = .camera
            takeImageVC.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            present(takeImageVC, animated: true)
        }
        else {
            UIService.showHUDWithNoAction(isSuccessful: false, with: "No camera available")
        }
    }
    
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
    
}

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
