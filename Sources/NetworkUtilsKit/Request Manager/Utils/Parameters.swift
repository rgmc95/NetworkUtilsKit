//
//  Parameters.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 22/01/2025.
//

import Foundation

public enum Parameters {
	case encodable(Encodable)
	case formURLEncoded([String: Any])
	case formData([String: Any])
	case other(type: (key: String, value: String), data: Data)
}
