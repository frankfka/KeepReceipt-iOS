//
//  SearchResultsTableViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-25.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import RealmSwift

class SearchResultsTableViewController: UITableViewController {
    
    var receiptsToShow: Results<Receipt>?
    var selectedReceipt: Receipt?

    override func viewDidLoad() {
        super.viewDidLoad()

        // Dismiss if somehow we did not load the receipts
        if receiptsToShow == nil {
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Something went wrong. Please try again.")
            dismiss(animated: true, completion: nil)
        }
        
        // Else register the relevant cell
        tableView.register(UINib(nibName: "ReceiptTableViewCell", bundle: nil), forCellReuseIdentifier: "ReceiptTableViewCell")
        
    }

    // MARK: - Tableview stuff
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return receiptsToShow!.count
    }

    // Initializes cell to display
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ReceiptTableViewCell") as! ReceiptTableViewCell
        // Don't do anything if the receipt is somehow nil
        if let receipt = receiptsToShow?[indexPath.row] {
            cell.initializeUI(for: receipt)
        }
        return cell
    }
    
    // Segue on click
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedReceipt = receiptsToShow![indexPath.row]
        performSegue(withIdentifier: "SearchResultsToDetailSegue", sender: self)
    }
    
    // Initialize the destination VC on click
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // There should be a receipt specified
        let destinationVC = segue.destination as! ViewReceiptViewController
        destinationVC.receipt = selectedReceipt
    }

}
