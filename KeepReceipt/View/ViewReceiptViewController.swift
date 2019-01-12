//
//  ViewReceiptViewController.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-11.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit
import SimpleImageViewer

class ViewReceiptViewController: UIViewController {
    
    // Receipt to show details for
    var receipt: Receipt?
    
    // UI Stuff
    @IBOutlet weak var receiptImageView: UIImageView!
    @IBOutlet weak var vendorNameLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if receipt != nil {
            loadViews()
        } else {
            // Go back if no receipt is found, this is an error case
            UIService.showHUDWithNoAction(isSuccessful: false, with: "Something went wrong")
            navigationController!.popViewController(animated: true)
        }

    }
    
    override func viewWillAppear(_ animated: Bool) {
        loadViews()
    }
    

    @IBAction func editButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "EditReceiptSegue", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "EditReceiptSegue" {
            let destinationVC = segue.destination as! AddOrEditReceiptViewController
            destinationVC.receiptToEdit = receipt
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        
        // Confirmation dialog
        let confirmationAlert = UIAlertController(title: "Delete Receipt", message: "Are you sure you want to delete this receipt?", preferredStyle: .alert)
        // Delete action
        confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
            
            // Delete the receipt - including the image
            DatabaseService.deleteReceipt(self.receipt!)
            // Go back to list of receipts
            self.navigationController!.popViewController(animated: true)
            
        }))
        // Cancel action
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
            // Do nothing
        }))
        
        // Present the alert
        self.present(confirmationAlert, animated: true, completion: nil)
        
    }
    
    // We use the SimpleImageViewer library to show an activity with fullscreen image
    @objc func imageTapped(tapGestureRecognizer: UITapGestureRecognizer) {
        
        if let tappedImage = tapGestureRecognizer.view as? UIImageView {
            let imageViewerConfig = ImageViewerConfiguration { config in
                config.imageView = tappedImage
            }
            let imageViewerController = ImageViewerController(configuration: imageViewerConfig)
            present(imageViewerController, animated: true)
        }
        
    }
    
    // Should only be called after checking for receipt non-nil, so we can force unwrap
    private func loadViews() {
        // Again, these fields are definitely set, but for future optional fields
        // we should do optional checking
        receiptImageView.image = ImageService.getImage(for: receipt!.receiptId!)
        vendorNameLabel.text = receipt?.vendor
        amountLabel.text = TextFormatService.getCurrencyString(for: receipt!.amount)
        dateLabel.text = TextFormatService.getDateString(for: receipt!.transactionTime!, fullMonth: true)
        
        // Add a recognizer to the ImageView so we can expand it on tap
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(imageTapped(tapGestureRecognizer:)))
        receiptImageView.isUserInteractionEnabled = true
        receiptImageView.addGestureRecognizer(tapGestureRecognizer)
    }
    

}
