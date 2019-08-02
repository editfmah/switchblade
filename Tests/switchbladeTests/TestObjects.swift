//
//  TestObjects.swift
//  SwitchbladeTests
//
//  Created by Adrian Herridge on 02/08/2019.
//

import Foundation

public class Person : Codable {
    
    init(){ PersonId = UUID() }
    public var PersonId : UUID?
    public var Name: String?
    public var Age: Int?
    public var DepartmentId : UUID?
    
}

public class Department : Codable {
    
    init(){ DepartmentId = UUID() }
    public var DepartmentId : UUID?
    public var DepartmentName: String?
    
}
