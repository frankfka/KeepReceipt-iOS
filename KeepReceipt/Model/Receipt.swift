//
//  Receipt.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-07.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import RealmSwift

class Receipt: Object {
    
    @objc dynamic var receiptId: String?
    @objc dynamic var backReceiptId: String = ""
    @objc dynamic var vendor: String = ""
    @objc dynamic var currency: String = ""
    @objc dynamic var amount: Double = 0
    @objc dynamic var transactionTime: Date?
    @objc dynamic var notes: String = ""
    let categories = LinkingObjects(fromType: Category.self, property: "receipts")
    
    override static func primaryKey() -> String? {
        return "receiptId"
    }
    
}
