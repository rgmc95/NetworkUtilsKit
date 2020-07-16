//
//  RequestMethod.swift
//  UtilsKit
//
//  Created by RGMC on 17/07/2019.
//  Copyright © 2019 RGMC. All rights reserved.
//

import Foundation

public enum RequestMethod: String {
    case connect = "CONNECT"
    case delete  = "DELETE"
    case get     = "GET"
    case head    = "HEAD"
    case options = "OPTIONS"
    case patch   = "PATCH"
    case post    = "POST"
    case put     = "PUT"
    case trace   = "TRACE"
}
