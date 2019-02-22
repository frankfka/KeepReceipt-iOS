//
//  CurrencyValueFormatter.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-02-21.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import Charts

public class CurrencyValueFormatter: NSObject, IAxisValueFormatter {
    
    private let numberFormatter = NumberFormatter()
    
    override init() {
        super.init()
        numberFormatter.numberStyle = .currency
        numberFormatter.currencySymbol = "$"
        numberFormatter.maximumFractionDigits = 0
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return numberFormatter.string(from: NSNumber(value: value))!
    }
    
}
