//
//  CategoryAnalyticsTableViewCell.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-02-10.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import UIKit

class CategoryAnalyticsTableViewCell: UITableViewCell {

    @IBOutlet weak var categoryNameLabel: UILabel!
    @IBOutlet weak var categoryPriceLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    func initializeUI(for categoryName: String, with spend: Double) {
        categoryNameLabel.text = categoryName
        categoryPriceLabel.text = TextFormatService.getCurrencyString(for: spend)
    }
    
}
