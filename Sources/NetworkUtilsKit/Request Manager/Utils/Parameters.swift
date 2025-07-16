//
//  Parameters.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 22/01/2025.
//

import Foundation

public enum Parameters: Sendable {
	case encodable(Encodable & Sendable)
	case formURLEncoded([String: Sendable])
	case formData([String: Sendable])
	case other(type: (key: String, value: String), data: Data)
}
