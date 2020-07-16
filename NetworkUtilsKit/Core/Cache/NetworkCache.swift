//
//  NetworkCache.swift
//  UtilsKit
//
//  Created by RGMC on 19/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation

private let kUserDefaultsName = "UtilsKit.NetworkCache"

internal struct NetworkCache {
    
    // MARK: - Singleton
    /// The shared singleton NetworkCache object
    internal static let shared = NetworkCache()
    
    // MARK: - Variables
    internal let defaults = UserDefaults(suiteName: kUserDefaultsName)
    
    // MARK: - Functions
    internal func set(_ datas: Data?, for key: String) {
        defaults?.setValue(datas, forKey: key)
    }
    
    internal func get(_ key: String) -> Data? {
        defaults?.value(forKey: key) as? Data
    }
    
    internal func delete(_ key: String) {
        defaults?.removeObject(forKey: key)
    }
    
    internal func resetCache() {
        self.defaults?.removePersistentDomain(forName: kUserDefaultsName)
    }
}
