//
//  DatabaseErrors.swift
//  Core
//
//  Created by Adrian Herridge on 01/08/2019.
//

import Foundation

public enum DatabaseError: Error {
    case Init(_ error: DatabaseInitError)
    case Query(_ error: DatabaseQueryError)
    case Execute(_ error: DatabaseExecuteError)
    case Schema
    case Performance
    case Unknown
}

public enum DatabaseInitError: Error {
    case UnableToConnectToServer
    case UnableToCreateLocalDatabase
}

public enum DatabaseExecuteError: Error {
    case SyntaxError(_ error: String)
}

public enum DatabaseQueryError: Error {
    case SyntaxError(_ error: String)
}

