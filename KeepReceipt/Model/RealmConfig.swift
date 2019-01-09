//
//  RealmConfig.swift
//  KeepReceipt
//
//  Created by Frank Jia on 2019-01-08.
//  Copyright © 2019 Frank Jia. All rights reserved.
//

import Foundation
import RealmSwift

class RealmConfig {
    
    static func defaultConfig() -> Realm.Configuration {
        return Realm.Configuration(objectTypes: [Receipt.self, Category.self])
    }
    
}
