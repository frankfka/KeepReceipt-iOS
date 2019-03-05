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
    
    // MARK: Receipt Methods
    
    // Save a receipt
    static func save(_ receipt: Receipt) {
        try! realm.write {
            realm.add(receipt)
        }
        //TODO update firebase
    }
    
    // Delete a receipt
    static func deleteReceipt(_ receipt: Receipt) {
        let imageId = receipt.receiptId!
        try! realm.write {
            realm.delete(receipt)
        }
        let deleteImageSuccess = ImageService.deleteImage(with: imageId)
        print("Deleted receipt, image deletion successful: \(deleteImageSuccess)")
        // TODO update firebase
    }
    
    // Update a receipt with new fields
    static func updateReceipt(_ receipt: Receipt, newVendor: String, newAmount: Double, newDate: Date) {
        try! realm.write {
            receipt.vendor = newVendor
            receipt.amount = newAmount
            receipt.transactionTime = newDate
        }
        // TODO update firebase
    }
    
    // MARK: Category Methods
    // Save a new category
    static func save(_ category: Category) {
        try! realm.write {
            realm.add(category)
        }
        // TODO update firebase
    }
    
    // Delete a category
    static func deleteCategory(_ category: Category) {
        try! realm.write {
            realm.delete(category)
        }
        // TODO firebase
    }
    
    // Update a category with existing fields
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
    
    // Imports all receipts from firebase
    static func importFromFirebase(for userId: String) {
        // TODO when we create stuff, make sure that the key isnt already taken or else
        // app will crash!
        
        // Get all the categories
        database.collection(ROOT_FIREBASE)
            .document(userId)
            .collection(ROOT_FIREBASE_CATEGORIES_COL)
            .getDocuments() { (categoriesQuery, categoriesErr) in
                if let error = categoriesErr {
                    // Error occured
                    print("Error getting documents: \(error)")
                } else {
                    // No error, go through all the categories
                    let allCurrentCategories = realm.objects(Category.self)
                    for document in categoriesQuery!.documents {
                        // Get name of category from firebase data
                        let firebaseCategoryName = document.data()["name"] as! String
                        // Add a new category if the category doesn't already exist
                        if allCurrentCategories.first(where: { (category) -> Bool in
                            category.name != nil ? category.name! == firebaseCategoryName : false
                        }) == nil {
                            print("Adding category \(firebaseCategoryName)")
                        } else {
                            print("Category \(firebaseCategoryName) already exists, skipping.")
                        }
                    }
                    
                    // Then we get all the receipts
                    database.collection(ROOT_FIREBASE)
                        .document(userId)
                        .collection(ROOT_FIREBASE_RECEIPTS_COL).getDocuments() { (receiptsQuery, receiptsErr) in
                        
                            if let error = receiptsErr {
                                // Error occured
                                print("Error getting documents: \(error)")
                            } else {
                                // No error, go through all the receipts
                                for document in receiptsQuery!.documents {
                                    print(document.data())
                                }
                            }
                    }
                    
                }
        }
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
