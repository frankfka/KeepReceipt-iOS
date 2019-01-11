//
//  ReceiptTableViewCell.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-10.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit

class ReceiptTableViewCell: UITableViewCell {
    
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var vendorNameLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var receiptImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func initializeUI(for receipt: Receipt) {
        
        // We can currently be sure that all these values exist
        // But once we add more, will need to do optional checking
        priceLabel.text = TextFormatService.getCurrencyString(for: receipt.amount)
        vendorNameLabel.text = receipt.vendor
        receiptImageView.image = ImageService.getImage(for: receipt.receiptId!)
        dateLabel.text = TextFormatService.getDateString(for: receipt.transactionTime!, fullMonth: true)
        
    }
    
}
