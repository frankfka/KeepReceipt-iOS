//
//  DatabaseService.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-11.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import RealmSwift

class DatabaseService {
    
    static let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    
    static func save(_ receipt: Receipt) {
        try! realm.write {
            realm.add(receipt)
        }
    }
    
    static func deleteReceipt(_ receipt: Receipt) {
        let imageId = receipt.receiptId!
        try! realm.write {
            realm.delete(receipt)
        }
        let deleteImageSuccess = ImageService.deleteImage(with: imageId)
        print("Deleted receipt, image deletion successful: \(deleteImageSuccess)")
    }
    
    // TODO refactor this using an enum once we add more fields
    static func updateReceipt(_ receipt: Receipt, newVendor: String, newAmount: Double, newDate: Date) {
        try! realm.write {
            receipt.vendor = newVendor
            receipt.amount = newAmount
            receipt.transactionTime = newDate
        }
    }
    
    static func updateCategory(for receipt: Receipt, from oldCategory: Category?, to newCategory: Category?) {
        try! realm.write {
            if oldCategory == nil && newCategory != nil {
                // Add to category
                newCategory!.receipts.append(receipt)
            } else if oldCategory != nil && newCategory == nil {
                // Remove previous category
                oldCategory!.receipts.remove(at: oldCategory!.receipts.index(of: receipt)!)
            } else if oldCategory != nil && newCategory != nil {
                // Remove previous category, add new category
                oldCategory!.receipts.remove(at: oldCategory!.receipts.index(of: receipt)!)
                newCategory!.receipts.append(receipt)
            }
        }
    }
}
