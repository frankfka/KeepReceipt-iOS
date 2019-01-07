//
//  Category.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-07.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import RealmSwift

class Category: Object {
    
    @objc dynamic var name: String?
    let receipts = List<Receipt>()
    
    override static func primaryKey() -> String? {
        return "name"
    }
    
}
