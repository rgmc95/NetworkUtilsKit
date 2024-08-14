//
//  File.swift
//  
//
//  Created by Michael Coqueret on 14/08/2024.
//

import OSLog

extension Logger {
	
	static let requestSend = Logger(subsystem: "Network", category: "Send")
	static let requestSuccess = Logger(subsystem: "Network", category: "Success")
	static let requestFail = Logger(subsystem: "Network", category: "Fail")
	static let requestCancel = Logger(subsystem: "Network", category: "Cancel")
	static let mock = Logger(subsystem: "Network", category: "Mock")
	static let cache = Logger(subsystem: "Network", category: "Cache")
	static let download = Logger(subsystem: "Network", category: "Download")
}
