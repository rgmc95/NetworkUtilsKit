//
//  RequestFile.swift
//  NetworkUtilsKit
//
//  Created by Michael Coqueret on 08/09/2023.
//

import Foundation

public struct RequestFile {
	public let key: String
	public let name: String
	public let type: String
	public let data: Data
	
	public init(key: String, name: String, type: String, data: Data) {
		self.key = key
		self.name = name
		self.type = type
		self.data = data
	}
}
