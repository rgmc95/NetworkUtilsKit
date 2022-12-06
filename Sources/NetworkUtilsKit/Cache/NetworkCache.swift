//
//  NetworkCache.swift
//  UtilsKit
//
//  Created by RGMC on 19/10/2018.
//  Copyright © 2018 RGMC. All rights reserved.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private let kUserDefaultsName = "UtilsKit.NetworkCache"

public struct CacheKey {
    let key: String
    let availableDate: Date
    
    public init?(key: String, days: Int? = nil, hours: Int? = nil, minutes: Int? = nil) {
        guard let date = Calendar.current.date(byAdding: DateComponents(day: days, hour: hours, minute: minutes),
                                               to: Date())
        else { return nil }
        
        self.key = key
        self.availableDate = date
    }
}

internal struct NetworkCache {
    
    // MARK: - Singleton
    /// The shared singleton NetworkCache object
    internal static let shared = NetworkCache()
    
    // MARK: - Variables
    internal let defaults = UserDefaults(suiteName: kUserDefaultsName)
    
    // MARK: - Functions
    internal func set(_ datas: Data?, for key: CacheKey) {
        self.defaults?.set(datas, forKey: key.key)
        self.defaults?.set(key.availableDate, forKey: "date_\(key.key)")
        self.defaults?.synchronize()
    }
    
    internal func get(_ key: CacheKey) -> Data? {
        guard
            let date = self.defaults?.object(forKey: "date_\(key.key)") as? Date,
            date >= Date()
        else {
            self.delete(key)
            return nil
        }
        return self.defaults?.object(forKey: key.key) as? Data
    }
    
    internal func delete(_ key: CacheKey) {
        self.defaults?.removeObject(forKey: key.key)
        self.defaults?.removeObject(forKey: "date_\(key.key)")
        self.defaults?.synchronize()
    }
    
    internal func resetCache() {
        self.defaults?.removePersistentDomain(forName: kUserDefaultsName)
        self.defaults?.synchronize()
    }
}
