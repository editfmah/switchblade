import Dispatch
import Foundation

public class Switchblade : SwitchbladeInterface {
    
    var provider: DataProvider
    var config: SwitchbladeConfig = SwitchbladeConfig()
    
    static var defaultProvider: DataProvider?
    
    public required init(provider: DataProvider, configuration: SwitchbladeConfig? = nil) throws {
        self.provider = provider
        if Switchblade.defaultProvider == nil {
            Switchblade.defaultProvider = provider
        }
        
        if let config = configuration {
            self.config = config
            self.provider.config = config
        } else {
            self.provider.config = SwitchbladeConfig()
        }
        
        // now, open the connection
        try self.provider.open()
    }
    
    public required init(provider: DataProvider, configuration: SwitchbladeConfig? = nil, completion: ((Bool, DataProvider, DatabaseError?) -> Void)?) {
        self.provider = provider
        if Switchblade.defaultProvider == nil {
            Switchblade.defaultProvider = provider
        }
        
        if let config = configuration {
            self.config = config
            self.provider.config = config
        } else {
            self.provider.config = SwitchbladeConfig()
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



