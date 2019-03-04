//
//  DatabaseService.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-11.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import RealmSwift
import FirebaseFirestore

let ROOT_FIREBASE = "users"
let ROOT_FIREBASE_RECEIPTS_COL = "receipts"
let ROOT_FIREBASE_CATEGORIES_COL = "categories"

class DatabaseService {
    
    static let realm = try! Realm(configuration: RealmConfig.defaultConfig())
    static let database = Firestore.firestore()
    
    static func save(_ receipt: Receipt) {
        try! realm.write {
            realm.add(receipt)
        }
        //TODO update firebase
    }
    
    static func deleteReceipt(_ receipt: Receipt) {
        let imageId = receipt.receiptId!
        try! realm.write {
            realm.delete(receipt)
        }
        let deleteImageSuccess = ImageService.deleteImage(with: imageId)
        print("Deleted receipt, image deletion successful: \(deleteImageSuccess)")
        // TODO update firebase
    }
    
    // TODO refactor this using an enum once we add more fields
    static func updateReceipt(_ receipt: Receipt, newVendor: String, newAmount: Double, newDate: Date) {
        try! realm.write {
            receipt.vendor = newVendor
            receipt.amount = newAmount
            receipt.transactionTime = newDate
        }
        // TODO update firebase
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
        // TODO update firebase
    }
    
    // Uploads all receipts to firebase and returns true if successful
    static func syncFirebaseForFirstTime(for userId: String) -> Bool {
        let allReceipts = realm.objects(Receipt.self)
        let allCategories = realm.objects(Category.self)
        
        for receipt in allReceipts {
            database.collection(ROOT_FIREBASE).document(userId)
                .collection(ROOT_FIREBASE_RECEIPTS_COL).document(receipt.receiptId!)
                .setData(getFirebaseDocument(for: receipt)) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
        
        for category in allCategories {
            database.collection(ROOT_FIREBASE).document(userId)
                    .collection(ROOT_FIREBASE_CATEGORIES_COL).document(category.name!)
                    .setData(getFirebaseDocument(for: category)) { err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                }
            }
        }
        
        return false
    }
    
    static func importFromFirebase() {
        // TODO
    }
    
    static private func getFirebaseDocument(for receipt: Receipt) -> [String: Any] {
        // Build categories array
        var categories: [String] = []
        for category in receipt.categories {
            categories.append(category.name!)
        }
        // Return the document
        return [
            "vendor": receipt.vendor,
            "amount": receipt.amount,
            "transactionTime": Timestamp(date: receipt.transactionTime!),
            "categories": categories
        ]
    }
    
    static private func getFirebaseDocument(for category: Category) -> [String: Any] {
        return ["name": category.name!]
    }
    
}
