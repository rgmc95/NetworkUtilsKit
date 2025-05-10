//
//  File.swift
//  
//
//  Created by Michael Coqueret on 14/08/2024.
//

import OSLog

extension Logger {
	
	static let requestSend = Logger(subsystem: "NetworkUtilsKit", category: "Send")
	static let requestSuccess = Logger(subsystem: "NetworkUtilsKit", category: "Success")
	static let requestFail = Logger(subsystem: "NetworkUtilsKit", category: "Fail")
	static let requestCancel = Logger(subsystem: "NetworkUtilsKit", category: "Cancel")
	static let mock = Logger(subsystem: "NetworkUtilsKit", category: "Mock")
	static let cache = Logger(subsystem: "NetworkUtilsKit", category: "Cache")
	static let download = Logger(subsystem: "NetworkUtilsKit", category: "Download")
}
