//
//  TextFormatService.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-10.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation

class TextFormatService {
    
    static func getCurrencyString(for amount: Double) -> String {
        return "$" + String(format: "%.2f", amount)
    }
    
    static func getDateString(for date: Date, fullMonth: Bool) -> String {
        let dateFormatter = DateFormatter()
        if (fullMonth) {
            dateFormatter.dateFormat = "MMMM dd, yyyy"
        } else {
            dateFormatter.dateFormat = "MMM dd, yyyy"
        }
        return dateFormatter.string(from: date)
    }
    
}
