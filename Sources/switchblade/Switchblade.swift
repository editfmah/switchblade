import Dispatch
import Foundation

public class Switchblade : SwitchbladeInterface {
    
    let instance: UUID = UUID()
    var provider: DataProvider
    var config: SwitchbladeConfig = SwitchbladeConfig()
    
    static var defaultProvider: DataProvider?
    
    // atomic functions
    static var locks: [UUID : Mutex] = [:]
    static var errors: [UUID : Bool] = [:]
    
    // binding registrations
    internal var bindings: [WeakContainer] = []
    
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
        
        Switchblade.locks[instance] = Mutex()
        Switchblade.errors[instance] = false
        self.provider.blade = self
        
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
        
        self.provider.blade = self
        
        // now, open the connection
        do {
            try self.provider.open()
            Switchblade.locks[instance] = Mutex()
            Switchblade.errors[instance] = false
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
    
    public func getCurrentProvider() -> DataProvider {
        return provider
    }
 
}

public enum SwitchbladeLogDriverLogType {
    case put
    case delete
}

public class SwitchbladeLogDriver {
    
    private struct Entry {
        var type: SwitchbladeLogDriverLogType
        var key: String
        var keyspace: Data
        var object: Data?
    }
    
    private var atomic = false
    private var filename = "switchblade.log"
    private var buffer: [Entry] = []
    private var lock = Mutex()
    private var outputLock = Mutex()
    
    public init(filename: String, atomic: Bool) {
        self.atomic = atomic
        self.filename = filename
        if atomic == false {
            
        }
    }
    
    public func log(type: SwitchbladeLogDriverLogType, key: String, keyspace: Data, object: Data?) {
        
    }
    
    private func flush() {
        
    }
    
    public func restore(switchblade: Switchblade) {
        // blocks and locks until log is restored into provider
        
    }
    
}

internal let kSaltValue = "dfc0e63c6cfd433087055cea149efb1f"

internal extension Switchblade {
    class WeakContainer {
        weak var value : AnyObject?
        var id: UUID = UUID()
        init (_ value: AnyObject) {
            self.value = value
            if let binding = value as? SwitchbladeBinding {
                self.id = binding.id
            }
        }
    }
}
