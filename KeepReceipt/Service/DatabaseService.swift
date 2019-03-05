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
    // Local storage has preference, items are skipped if they are already present (even though they might have different properties)
    static func importFromFirebase(for userId: String) {
        
        // Get all the categories
        database.collection(ROOT_FIREBASE)
            .document(userId)
            .collection(ROOT_FIREBASE_CATEGORIES_COL)
            .getDocuments() { (categoriesQuery, categoriesErr) in
                if categoriesErr == nil {
                    // No error, go through all the categories
                    let allCurrentCategories = realm.objects(Category.self)
                    for document in categoriesQuery!.documents {
                        // Get name of category from firebase data
                        let newCategory = getCategory(for: document)
                        // Add a new category if the category doesn't already exist
                        if allCurrentCategories.first(where: { (category) -> Bool in
                            category.name != nil ? category.name! == newCategory.name! : false
                        }) == nil {
                            print("Adding category \(newCategory.name!)")
                            // TODO actually add the category
                        } else {
                            print("Category \(newCategory.name!) already exists, skipping.")
                        }
                    }
                    
                    // Then we get all the receipts
                    database.collection(ROOT_FIREBASE)
                        .document(userId)
                        .collection(ROOT_FIREBASE_RECEIPTS_COL).getDocuments() { (receiptsQuery, receiptsErr) in
                            
                            if receiptsErr == nil {
                                // No error, go through all the receipts
                                let allCurrentReceipts = realm.objects(Receipt.self)
                                for document in receiptsQuery!.documents {
                                    // Get all the fields
                                    let newReceipt = getReceipt(for: document)
                                    
                                    if allCurrentReceipts.first(where: { (receipt) -> Bool in
                                        return receipt.receiptId != nil ? receipt.receiptId! == newReceipt.receiptId : false
                                    }) == nil {
                                        let categories = document.data()["categories"] as! [String]
                                        print("Adding receipt \(newReceipt.receiptId!)")
                                        // TODO actually add the receipt
                                    } else {
                                        print("Receipt \(newReceipt.receiptId!) already exists, skipping.")
                                    }
                                }
                                
                                // TODO add categories after committing object
                            } else {
                                // Error occured
                                print("Error getting receipt documents: \(receiptsErr!)")
                            }
                    }
                } else {
                    // Error occured
                    print("Error getting category documents: \(categoriesErr!)")
                }
        }
    }
    
    // MARK: Firebase helper methods
    // Get firebase document for a receipt
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
    
    // Get firebase document for a category
    static private func getFirebaseDocument(for category: Category) -> [String: Any] {
        return ["name": category.name!]
    }
    
    // Get a category from a firebase document
    static private func getCategory(for document: QueryDocumentSnapshot) -> Category {
        let firebaseCategoryName = document.data()["name"] as! String
        let newCategory = Category()
        newCategory.name = firebaseCategoryName
        return newCategory
    }
    
    // Get a reciept from a firebase document
    // IGNORES category field for now!
    static private func getReceipt(for document: QueryDocumentSnapshot) -> Receipt {
        // Get fields
        let data = document.data()
        let receiptId = document.documentID
        let vendor = data["vendor"] as! String
        let amount = data["amount"] as! Double
        let transactionTime = (data["transactionTime"] as! Timestamp).dateValue()
        
        // Create object
        let newReceipt = Receipt()
        newReceipt.receiptId = receiptId
        newReceipt.vendor = vendor
        newReceipt.amount = amount
        newReceipt.transactionTime = transactionTime
        
        return newReceipt
    }
    
}
