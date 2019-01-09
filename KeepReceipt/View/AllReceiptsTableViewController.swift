//
//  AllReceiptsTableViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import SVProgressHUD
import RealmSwift

class AllReceiptsTableViewController: UITableViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    var allReceipts: Results<Receipt>?
    // Displayed may not be all in the case that a search is entered
    var displayedReceipts: Results<Receipt>?
    
    // For the add button
    var receiptImageToAdd: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Initialize the data
        allReceipts = realm.objects(Receipt.self)
        displayedReceipts = realm.objects(Receipt.self)

        // Register custom tableview cell
//        tableView.register(UINib(nibName: "RestaurantCell", bundle: nil), forCellReuseIdentifier: "restaurantCell")
        
        
    }

    // MARK: - Table view data source
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayedReceipts?.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Get an unused cell - TODO use a formatted cell instead
        let cell = tableView.dequeueReusableCell(withIdentifier: "tempReceiptCell")!
        // Don't do anything if the receipt is somehow nil
        if let receipt = displayedReceipts?[indexPath.row] {
            cell.textLabel?.text = receipt.vendor
        }
        return cell
        
    }

    @IBAction func addNewReceiptPressed(_ sender: UIBarButtonItem) {
        
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            let takeImageVC = UIImagePickerController()
            takeImageVC.sourceType = .camera
            takeImageVC.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
            present(takeImageVC, animated: true)
        }
        else {
            SVProgressHUD.showError(withStatus: "No Camera is Available")
            SVProgressHUD.dismiss(withDelay: TimeInterval(2))
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
            let destinationVC = segue.destination as! AddReceiptViewController
            destinationVC.receiptImage = receiptImageToAdd
        }
        // Else do nothing
    }
    
}
