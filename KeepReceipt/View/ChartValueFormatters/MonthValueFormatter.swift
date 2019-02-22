//
//  MonthValueFormatter.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-02-21.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import Charts

public class MonthValueFormatter: NSObject, IAxisValueFormatter {
    private let dateFormatter = DateFormatter()
    
    override init() {
        super.init()
        dateFormatter.dateFormat = "MMM"
    }
    
    public func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        return dateFormatter.string(from: Date(timeIntervalSince1970: value))
    }
}
