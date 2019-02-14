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
    
    static func getMonthString(for monthNumber: Int, fullMonth: Bool) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM"
        let date = dateFormatter.date(from: "\(monthNumber)")
        if (fullMonth) {
            dateFormatter.dateFormat = "MMMM"
        } else {
            dateFormatter.dateFormat = "MMM"
        }
        return dateFormatter.string(from: date!)
    }
    
    static func getMonthAndYearString(for date: Date, fullMonth: Bool) -> String {
        let dateFormatter = DateFormatter()
        if (fullMonth) {
            dateFormatter.dateFormat = "MMMM yyyy"
        } else {
            dateFormatter.dateFormat = "MMM yyyy"
        }
        return dateFormatter.string(from: date)
    }
    
}
