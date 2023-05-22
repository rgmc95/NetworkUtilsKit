//
//  NetworkLogType.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 21/01/2021.
//  Copyright © 2021 RGMC. All rights reserved.
//

#if canImport(UtilsKitCore)
import UtilsKitCore
#endif

#if canImport(UtilsKit)
import UtilsKit
#endif

/**
 Network Log type.
 */
internal enum NetworkLogType: LogType {
	case sending
	case success
	case successWarning
	case error
	case cache
	case cancel
	
	case download
	case mock
	
	internal var prefix: String {
		switch self {
		case .sending: return "➡️"
		case .cancel: return "⏹️"
		case .success: return "✅"
		case .successWarning: return "✅⚠️"
		case .cache: return "✅ 🗄"
		case .error: return "❌"
		case .download: return "📲"
		case .mock: return "🍾"
		}
	}
}
