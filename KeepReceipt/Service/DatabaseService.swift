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
import FirebaseAuth

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
        // Save to firebase
        if let userId = Auth.auth().currentUser?.uid {
            if UserDefaults.standard.bool(forKey: Settings.SYNC_ENABLED) {
                print("Sync enabled. Saving receipt to Firebase")
                addToFirebase(receipt: receipt, for: userId)
            }
        }
    }
    
    // Delete a receipt
    static func deleteReceipt(_ receipt: Receipt) {
        let imageId = receipt.receiptId!
        // Delete from firebase first
        if let userId = Auth.auth().currentUser?.uid {
            if UserDefaults.standard.bool(forKey: Settings.SYNC_ENABLED) {
                print("Sync enabled. Deleting receipt from Firebase")
                deleteFromFirebase(receipt: receipt, for: userId)
            }
        }
        try! realm.write {
            realm.delete(receipt)
        }
        let deleteImageSuccess = ImageService.deleteImage(with: imageId)
        print("Deleted receipt, image deletion successful: \(deleteImageSuccess)")
    }
    
    // Update a receipt with new fields
    static func updateReceipt(_ receipt: Receipt, newVendor: String, newAmount: Double, newDate: Date) {
        try! realm.write {
            receipt.vendor = newVendor
            receipt.amount = newAmount
            receipt.transactionTime = newDate
        }
        // Existing document will be overwritten
        if let userId = Auth.auth().currentUser?.uid {
            if UserDefaults.standard.bool(forKey: Settings.SYNC_ENABLED) {
                print("Sync enabled. Updating receipt on Firebase")
                addToFirebase(receipt: receipt, for: userId)
            }
        }
    }
    
    // MARK: Category Methods
    // Save a new category
    static func save(_ category: Category) {
        try! realm.write {
            realm.add(category)
        }
        // Save to firebase
        if let userId = Auth.auth().currentUser?.uid {
            if UserDefaults.standard.bool(forKey: Settings.SYNC_ENABLED) {
                print("Sync enabled. Saving category to Firebase")
                addToFirebase(category: category, for: userId)
            }
        }
    }
    
    // Delete a category
    static func deleteCategory(_ category: Category) {
        // Delete from firebase first
        if let userId = Auth.auth().currentUser?.uid {
            if UserDefaults.standard.bool(forKey: Settings.SYNC_ENABLED) {
                print("Sync enabled. Deleting category from Firebase")
                deleteFromFirebase(category: category, for: userId)
            }
        }
        try! realm.write {
            realm.delete(category)
        }
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
        // Just add the receipt to firebase - it will be overwritten
        if let userId = Auth.auth().currentUser?.uid {
            if UserDefaults.standard.bool(forKey: Settings.SYNC_ENABLED) {
                print("Sync enabled. Updating category to Firebase")
                addToFirebase(receipt: receipt, for: userId)
            }
        }
    }
    
    // Uploads all receipts to firebase and returns true if successful
    static func syncFirebase() {
        let userId = Auth.auth().currentUser?.uid
        // Return if no user logged in
        if userId == nil {
            return
        }
        
        let allReceipts = realm.objects(Receipt.self)
        let allCategories = realm.objects(Category.self)
        
        for receipt in allReceipts {
            addToFirebase(receipt: receipt, for: userId!)
        }
        for category in allCategories {
            addToFirebase(category: category, for: userId!)
        }
    }
    
    // Imports all receipts from firebase
    // Local storage has preference, items are skipped if they are already present (even though they might have different properties)
    static func importFromFirebase() {
        let userId = Auth.auth().currentUser?.uid
        // Return if no user logged in
        if userId == nil {
            return
        }
        
        // Get all the categories
        database.collection(ROOT_FIREBASE)
            .document(userId!)
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
                            try! realm.write {
                                realm.add(newCategory)
                            }
                        } else {
                            print("Category \(newCategory.name!) already exists, skipping.")
                        }
                    }
                    
                    // Then we get all the receipts
                    database.collection(ROOT_FIREBASE)
                        .document(userId!)
                        .collection(ROOT_FIREBASE_RECEIPTS_COL).getDocuments() { (receiptsQuery, receiptsErr) in
                            
                            if receiptsErr == nil {
                                // No error, go through all the receipts
                                let allCurrentReceipts = realm.objects(Receipt.self)
                                for document in receiptsQuery!.documents {
                                    // Get all the fields
                                    let newReceipt = getReceipt(for: document)
                                    // Add the new receipt if it does not already exist
                                    if allCurrentReceipts.first(where: { (receipt) -> Bool in
                                        return receipt.receiptId != nil ? receipt.receiptId! == newReceipt.receiptId : false
                                    }) == nil {
                                        print("Adding receipt \(newReceipt.receiptId!)")
                                        
                                        // Get the list of categories
                                        let categories = document.data()["categories"] as! [String]
                                        try! realm.write {
                                            // Add the receipt to realm
                                            realm.add(newReceipt)
                                            for categoryName in categories {
                                                // Find the category to add this receipt to & add it if it exists
                                                if let category = allCurrentCategories.first(where: { (category) -> Bool in
                                                    category.name != nil ? category.name! == categoryName : false
                                                }) {
                                                    category.receipts.append(newReceipt)
                                                }
                                            }
                                        }
                                    } else {
                                        print("Receipt \(newReceipt.receiptId!) already exists, skipping.")
                                    }
                                }
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
    // Adds a receipt document to firebase
    static private func addToFirebase(receipt: Receipt, for userId: String) {
        database.collection(ROOT_FIREBASE).document(userId)
            .collection(ROOT_FIREBASE_RECEIPTS_COL).document(receipt.receiptId!)
            .setData(getFirebaseDocument(for: receipt)) { err in
                if let err = err {
                    print("Error writing receipt \(receipt.receiptId!): \(err)")
                }
        }
    }
    
    // Adds a category document to firebase
    static private func addToFirebase(category: Category, for userId: String) {
        database.collection(ROOT_FIREBASE).document(userId)
            .collection(ROOT_FIREBASE_CATEGORIES_COL).document(category.name!)
            .setData(getFirebaseDocument(for: category)) { err in
                if let err = err {
                    print("Error writing category \(category.name!): \(err)")
                }
        }
    }
    
    // Deletes a receipt document from firebase
    static private func deleteFromFirebase(receipt: Receipt, for userId: String) {
        database.collection(ROOT_FIREBASE).document(userId)
            .collection(ROOT_FIREBASE_RECEIPTS_COL).document(receipt.receiptId!)
            .delete()
    }
    
    // Deletes a category document from firebase
    static private func deleteFromFirebase(category: Category, for userId: String) {
        database.collection(ROOT_FIREBASE).document(userId)
            .collection(ROOT_FIREBASE_CATEGORIES_COL).document(category.name!)
            .delete()
    }
    
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
