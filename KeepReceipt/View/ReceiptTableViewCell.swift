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
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func initializeUI(for receipt: Receipt) {
        // do cell setup here
    }
    
}
