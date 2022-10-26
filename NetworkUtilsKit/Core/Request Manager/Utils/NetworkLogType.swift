//
//  NetworkLogType.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 21/01/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

import UtilsKit

/**
 Network Log type.
 */
internal enum NetworkLogType: LogType {
	case sending
	case success
	case successWarning
	case error
	case cache
	
	case download
	case mock
	
	internal var prefix: String {
		switch self {
		case .sending: return "➡️"
		case .success: return "✅"
		case .successWarning: return "✅⚠️"
		case .cache: return "✅ 🗄"
		case .error: return "❌"
		case .download: return "📲"
		case .mock: return "🍾"
		}
	}
}
