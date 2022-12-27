//
//  TestObjects.swift
//  SwitchbladeTests
//
//  Created by Adrian Herridge on 02/08/2019.
//

import Foundation
import Switchblade

public class Person : Codable, Identifiable, KeyspaceIdentifiable {
    
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

public class PersonFilterable : Codable, Filterable, Identifiable, KeyspaceIdentifiable {
    
    public var filters: [String : String] {
        get {
            return ["type" : "person", "age" : "\(self.Age ?? 0)", "name" : self.Name ?? ""]
        }
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

public class PersonVersion1 : Codable, SchemaVersioned {
    
    public static var version: (objectName: String, version: Int) = ("Person", 1)
    
    
    public var id : UUID = UUID()
    public var name: String?
    public var age: Int?
    
}

public class PersonVersion2 : Codable, SchemaVersioned {
    
    public static var version: (objectName: String, version: Int) = ("Person", 2)
    
    public var id : UUID = UUID()
    public var forename: String?
    public var surname: String?
    public var age: Int?
    
}

