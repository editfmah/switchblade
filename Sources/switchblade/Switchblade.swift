import Dispatch
import Foundation

public class Switchblade : SwitchbladeInterface {
    
    var provider: DataProvider
    static var defaultProvider: DataProvider?
    
    required public init(provider: DataProvider) throws {
        
        self.provider = provider
        if Switchblade.defaultProvider == nil {
            Switchblade.defaultProvider = provider
        }
        
        // now, open the connection
        try self.provider.open()
        
    }
    required
    public init(provider: DataProvider, completion:((_ success: Bool,_ provider: DataProvider, _ error: DatabaseError?) -> Void)?) {
        
        self.provider = provider
        if Switchblade.defaultProvider == nil {
            Switchblade.defaultProvider = provider
        }
        
        // now, open the connection
        do {
            try self.provider.open()
            completion?(true, provider, nil)
        } catch DatabaseError.Init(let e) {
            completion?(false, provider, DatabaseError.Init(e))
        } catch {
            completion?(false, provider, DatabaseError.Unknown)
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
 
}



