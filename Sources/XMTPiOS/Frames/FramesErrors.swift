//
//  File.swift
//  
//
//  Created by Alex Risch on 3/28/24.
//

import Foundation

enum FramesApiError: Error {
    case customError(String, Int)
    
    var localizedDescription: String {
        switch self {
        case .customError(let message, let status):
            return "Message: \(message), Status: \(status)"
        }
    }
    
    var status: Int {
        switch self {
        case .customError(_, let status):
            return status
        }
    }
}

class InvalidArgumentsError: Error {
    
}

