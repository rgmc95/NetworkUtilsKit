//
//  Encoding.swift
//  UtilsKit
//
//  Created by RGMC on 17/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
//

import Foundation

/// Request encoding case
public enum Encoding {
    /// URL encoding
    case url
    
    /// JSON encoding
    case json
    
#if canImport(CoreServices)
    /// Form Data
    case formData
#endif
}
