//
//  TestObjects.swift
//  SwitchbladeTests
//
//  Created by Adrian Herridge on 02/08/2019.
//

import Foundation
import Switchblade

public class Person : Codable, Identifiable, KeyspaceIdentifiable, Queryable {
    
    public var queryableItems: [String : Any?] {
        return ["name" : self.Name, "age" : self.Age, "department" : self.DepartmentId]
    }
    
    public var key: PrimaryKeyType {
        return self.PersonId
    }
    
    public var keyspace: String {
        return "person"
    }
    
    init(){ PersonId = UUID() }
    public var PersonId : UUID
    public var Name: String?
    public var Age: Int?
    public var DepartmentId : UUID?
    
}

