//
//  AnalyticsService.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-02-12.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import RealmSwift

class AnalyticsService {
    
    static func getTotalSpend(for receipts: Results<Receipt>, startTime: Date, endTime: Date) -> Double {
        
        let timePeriodQueryPredicates = [
            // Greater than first of month
            NSPredicate(format: "transactionTime >= %@", NSDate(timeInterval: 0, since: startTime)),
            // Less than last of month
            NSPredicate(format: "transactionTime < %@", NSDate(timeInterval: 0, since: endTime))
        ]
        
        // Total spend this month
        let displayMonthQuery = NSCompoundPredicate(andPredicateWithSubpredicates: timePeriodQueryPredicates)
        return getTotalSpend(for: receipts.filter(displayMonthQuery))
    }
    
    static func getTotalSpend(for receipts: Results<Receipt>) -> Double {
        
        var totalSpend = 0.0
        for receipt in receipts {
            totalSpend = totalSpend + receipt.amount
        }
        return totalSpend
        
    }
    
}
