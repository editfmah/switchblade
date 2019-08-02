import Dispatch
import Foundation

public class Switchblade {
    
    var provider: DataProvider
    
    static var defaultProvider: DataProvider?
    
    public init(provider: DataProvider) throws {
        
        self.provider = provider
        if Switchblade.defaultProvider == nil {
            Switchblade.defaultProvider = provider
        }
        
        // now, open the connection
        try self.provider.open()
        
    }
    
    public init(provider: DataProvider, completion:((_ success: Bool, _ error: DatabaseError?) -> Void)?) {
        
        self.provider = provider
        if Switchblade.defaultProvider == nil {
            Switchblade.defaultProvider = provider
        }
        
        // now, open the connection
        do {
            try self.provider.open()
            completion?(true, nil)
        } catch DatabaseError.Init(let e) {
            completion?(false, DatabaseError.Init(e))
        } catch {
            completion?(false, DatabaseError.Unknown)
        }
        
    }
    
    public func close() throws {
        try self.provider.close()
    }
    
    public func close(completion:((_ success: Bool, _ error: DatabaseError?) -> Void)?) {
        do {
            try self.provider.close()
            completion?(true, nil)
        } catch DatabaseError.Init(let e) {
            completion?(false, DatabaseError.Init(e))
        } catch {
            completion?(false, DatabaseError.Unknown)
        }
    }
    
    // ASYNC METHODS
    public func create<T>(_ object: T, pk: String, auto: Bool, indexes: [String], completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) where T: Codable {
        
        do {
            try self.provider.create(object, pk: pk, auto: auto, indexes: indexes)
        } catch DatabaseError.Schema {
            completion?(false, DatabaseError.Schema)
        } catch {
            completion?(false, .Unknown)
        }
        
    }
    
    public func put<T>(_ object: T, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable {
        
        self.provider.put(object) { (success, error) in
            completion?(success,error)
        }
        
    }
    
    public func query<T>(_ object: T,_ parameters: [param], completion: ((_ results: [T],_ error: DatabaseError?) -> Void)?) -> Void where T: Codable {
        
        self.provider.query(object, parameters: parameters) { (results, error) in
            completion?(results, error)
        }
        
    }
    
    public func query<T>(_ object: T,_ param: param, completion: ((_ results: [T],_ error: DatabaseError?) -> Void)?) -> Void where T: Codable {
        
        self.provider.query(object, parameters: [param]) { (results, error) in
            completion?(results, error)
        }
        
    }
    
    public func delete<T>(_ object: T,_ parameters: [param], completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable {
        
        self.provider.delete(object, parameters: parameters) { (success, error) in
            completion?(success, error)
        }
        
    }
    
    public func delete<T>(_ object: T,_ param: param, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable {
        
        self.provider.delete(object, parameters: [param]) { (success, error) in
            completion?(success, error)
        }
        
    }
    
    public func delete<T>(_ object: T, completion: ((_ success: Bool,_ error: DatabaseError?) -> Void)?) -> Void where T: Codable {
        
        self.provider.delete(object) { (success, error) in
            completion?(success, error)
        }
        
    }
    
    
    // SYNC METHODS
    public func create<T>(_ object: T, pk: String, auto: Bool, indexes: [String]) throws where T: Codable {
        try self.provider.create(object, pk: pk, auto: auto, indexes: indexes)
    }
    
    public func put<T>(_ object: T) throws -> Bool where T: Codable {
        
        let waiter = DispatchSemaphore(value: 0)
        var funcerror: DatabaseError? = nil
        self.provider.put(object) { (success, error) in
            if error != nil {
                funcerror = error!
            }
            waiter.signal()
        }
        waiter.wait()
        if funcerror != nil {
            throw funcerror!
        }
        return true
        
    }
    
    public func query<T>(_ object: T,_ parameters: [param]) throws -> [T] where T: Codable {
        
        let waiter = DispatchSemaphore(value: 0)
        var funcerror: DatabaseError? = nil
        var r: [T] = []
        self.provider.query(object, parameters: parameters) { (results, error) in
            if error != nil {
                funcerror = error!
            } else {
                r = results
            }
            waiter.signal()
        }
        waiter.wait()
        if funcerror != nil {
            throw funcerror!
        }
        return r
        
    }
    
    public func query<T>(_ object: T,_ param: param) throws -> [T] where T: Codable {
        let waiter = DispatchSemaphore(value: 0)
        var funcerror: DatabaseError? = nil
        var r: [T] = []
        self.provider.query(object, parameters: [param]) { (results, error) in
            if error != nil {
                funcerror = error!
            } else {
                r = results
            }
            waiter.signal()
        }
        waiter.wait()
        if funcerror != nil {
            throw funcerror!
        }
        return r
    }
    
    public func delete<T>(_ object: T,_ parameters: [param]) throws -> Bool where T: Codable {
        
        let waiter = DispatchSemaphore(value: 0)
        var funcerror: DatabaseError? = nil
        self.provider.delete(object, parameters: parameters) { (success, error) in
            if error != nil {
                funcerror = error!
            }
            waiter.signal()
        }
        waiter.wait()
        if funcerror != nil {
            throw funcerror!
        }
        return true
        
    }
    
    public func delete<T>(_ object: T,_ param: param) throws -> Bool where T: Codable {
        
        let waiter = DispatchSemaphore(value: 0)
        var funcerror: DatabaseError? = nil
        self.provider.delete(object, parameters: [param]) { (success, error) in
            if error != nil {
                funcerror = error!
            }
            waiter.signal()
        }
        waiter.wait()
        if funcerror != nil {
            throw funcerror!
        }
        return true
        
    }
    
    public func delete<T>(_ object: T) throws -> Bool where T: Codable {
        
        let waiter = DispatchSemaphore(value: 0)
        var funcerror: DatabaseError? = nil
        self.provider.delete(object) { (success, error) in
            if error != nil {
                funcerror = error!
            }
            waiter.signal()
        }
        waiter.wait()
        if funcerror != nil {
            throw funcerror!
        }
        return true
        
    }

 
}


