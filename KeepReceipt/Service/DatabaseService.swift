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
    
}
