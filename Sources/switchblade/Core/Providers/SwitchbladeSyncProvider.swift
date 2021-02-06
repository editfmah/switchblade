//
//  SwitchbladeSyncProvider.swift
//  Switchblade
//
//  Created by Adrian Herridge on 23/09/2020.
//

import Dispatch
import CryptoSwift

#if canImport(FoundationNetworking)
import FoundationNetworking
#else
import Foundation
#endif

fileprivate var kSyncedKeyspaces = "49cedefa8f974d2784f4d37d74bf737b"
fileprivate var kOutstandingChangeIds = "f326a95fc85f4b33b4942457e642c8b5"
fileprivate var kSyncOriginId = "7e8742b77d164903bd050c46ff2c49a0"
fileprivate var kKeyspaceTidemarkId = "5141942fa52e4527a007e9e61a797e49"
fileprivate var kChangedDataKeyspace = "9a34468ffc52448d8698c8ea473585e8".data(using: .utf8)!

internal var ServiceEndpoint = "http://localhost:20010"

fileprivate func makeRecordId(_ key: Data,_ keyspace: Data) -> Data {
    var id = Data(key)
    id.append(keyspace)
    return id.sha224()
}

fileprivate func makeId(_ key: Data,_ keyspace: Data) -> Data {
    var id = Data(key)
    id.append(keyspace)
    id.append(kChangedDataKeyspace)
    return id.sha224()
}

internal enum NetworkRequestServiceStatus : String, Codable {
    case light = "light"
    case medium = "medium"
    case heavy = "heavy"
}

internal enum NetworkRequestTransactionType : String, Codable {
    case PUT = "PUT"
    case DELETE = "DELETE"
}

internal class NetworkRequestTransaction: Codable {
    var origin: UUID? // origin id to stop re-writing changes made from this account
    var key: Data?
    var keyspace: Data?
    var value: Data?
    var queryable: [Data] = []
    var type: NetworkRequestTransactionType?
    var timestamp: Int?
}

internal class NetworkRequestObject: Codable {
    var accountId: String?
    var instanceId: String?
    var secret: String?
    var keyspace: Data?
    var tidemark: Int?
    var transactions: [NetworkRequestTransaction] = []
    var eot: Bool?
    var status: NetworkRequestServiceStatus?
}

fileprivate class SwitchbladeSyncKeyspace: DataProvider {
    
    var config: SwitchbladeConfig!
    
    func transact(_ mode: transaction) -> Bool {
        return true
    }
    
    fileprivate var provider: DataProvider!
    public weak var blade: Switchblade!
    fileprivate var lock = Mutex()
    
    // internal vars for status
    fileprivate var changedIds: [Data]!
    fileprivate var tidemark: Int
    fileprivate var origin: UUID
    
    var db: OpaquePointer?
    private var p: String?
    let decoder: JSONDecoder = JSONDecoder()
    let urgency: SyncUrgency
    let active: Bool = true
    
    public init(localProvider: DataProvider, accountId: String, instanceId: String, keyspace: Data, priority: SyncUrgency) {
        
        provider = localProvider
        urgency = priority
        config = localProvider.config
        
        // create local cache table for changes
        if let changed: [Data] = provider.get(key: makeRecordId(kOutstandingChangeIds.key(), keyspace), keyspace: kChangedDataKeyspace) {
            changedIds = changed
        } else {
            changedIds = []
        }
        if let originId: UUID = provider.get(key: kSyncOriginId.key(), keyspace: kChangedDataKeyspace) {
            origin = originId
        } else {
            origin = UUID()
            provider.put(key: kSyncOriginId.key(), keyspace: kChangedDataKeyspace, origin)
        }
        if let storedTidemark: Int = provider.get(key: makeRecordId(kKeyspaceTidemarkId.key(), keyspace), keyspace: kChangedDataKeyspace) {
            tidemark = storedTidemark
        } else {
            tidemark = 0
            provider.put(key: makeRecordId(kKeyspaceTidemarkId.key(), keyspace), keyspace: kChangedDataKeyspace, tidemark)
        }
        Execute.forever { [weak self] in
            if let self = self {
                
                if self.active {
                    // send and receive data
                    self.lock.mutex {
                        // get the list of changes for this sync request, and the current tidemark
                        let request = NetworkRequestObject()
                        request.accountId = accountId
                        request.instanceId = instanceId
                        request.tidemark = self.tidemark
                        request.keyspace = keyspace
                        
                        var first: [Data]?
                        
                        if !self.changedIds.isEmpty {
                            // right, lets package these up and send them off as a new request
                            first = Array(self.changedIds.prefix(200))
                            for id in first ?? [] {
                                if let transaction: NetworkRequestTransaction = self.provider.get(key: id, keyspace: kChangedDataKeyspace) {
                                    request.transactions.append(transaction)
                                }
                            }
                        }
                        
                        // send this request off to the network handler, and block until complete.  Because we are already on a background thread
                        if let response = self.makeRequest(request: request) {
                            // go through the response and update the local objects with these objects
                            for transaction in response.transactions {
                                if let type = transaction.type, transaction.origin != self.origin {
                                    switch type {
                                    case .PUT:
                                        // upsert this data into the database
                                        if let provider = self.provider as? DataProviderPrivate {
                                            if let datakey = transaction.key, let keyspace = transaction.keyspace {
                                                // check for an encryption key
                                                if let encKey = self.provider.config.aes256encryptionKey {
                                                    let key = encKey.sha256()
                                                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                                                    do {
                                                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                                                        let decryptedBytes = try aes.decrypt(transaction.value!.bytes)
                                                        let decryptedData = Data(decryptedBytes)
                                                        provider.put(key: datakey, keyspace: keyspace, object: decryptedData, queryKeys: transaction.queryable)
                                                    } catch {
                                                        assertionFailure("encryption error: \(error)")
                                                    }
                                                } else {
                                                    
                                                }
                                            }
                                            
                                        }
                                    case .DELETE:
                                        self.provider.delete(key: transaction.key!, keyspace: transaction.keyspace!)
                                    }
                                }
                            }
                        }
                        
                    }
                    
                    // now wait for the correct interval
                    switch self.urgency {
                    case .superlow:
                        Thread.sleep(forTimeInterval: 120)
                    case .low:
                        Thread.sleep(forTimeInterval: 60)
                    case .medium:
                        Thread.sleep(forTimeInterval: 30)
                    case .high:
                        Thread.sleep(forTimeInterval: 15)
                    case .veryhigh:
                        Thread.sleep(forTimeInterval: 5)
                    }
                }
                
            }
        }
    }
    
    public func open() throws {
        
    }
    
    public func close() throws {
        
    }
    
    internal func makeRequest(request: NetworkRequestObject) -> NetworkRequestObject? {
        
        var urlRequest = URLRequest(url: URL(string: "\(ServiceEndpoint)/api/v1/sync")!)
        
        urlRequest.httpMethod = "POST"
        urlRequest.addValue("application/json",forHTTPHeaderField: "Content-Type")
        urlRequest.addValue("application/json",forHTTPHeaderField: "Accept")
        urlRequest.httpBody = try? JSONEncoder().encode(request)
        let waiter = DispatchSemaphore(value: 0)
        var response: NetworkRequestObject? = nil
        
        let task = URLSession.shared.dataTask(with: urlRequest) { (data, res, err) in
            if err == nil && data != nil {
                response = try? JSONDecoder().decode(NetworkRequestObject.self, from: data!)
            }
            waiter.signal()
        }
        task.resume()
        waiter.wait()
        return response
        
    }
    
    fileprivate func hashParam(_ key: Data,_ paramValue: Any?) -> Data {
        var hash = key
        if let value = paramValue as? Date {
            hash += Data("\(value.timeIntervalSince1970)".bytes)
        } else if let value = paramValue {
            hash += Data("\(value)".bytes)
        }
        return hash.sha256()
    }
    
    fileprivate func sync(internalId: Data, _ object: NetworkRequestTransaction) -> Bool {
        
        lock.mutex {
            
            if !changedIds.contains(internalId) {
                changedIds.append(internalId)
                provider.put(key: makeRecordId(kOutstandingChangeIds.key(), object.keyspace!), keyspace: kChangedDataKeyspace, changedIds)
            }
            
            provider.put(key: internalId, keyspace: kChangedDataKeyspace, object)
            
        }
        
        return true
        
    }
    
    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        let id = makeId(key, keyspace)
        let transaction = NetworkRequestTransaction()
        transaction.origin = origin
        transaction.key = key
        transaction.keyspace = keyspace
        transaction.timestamp = Int(Date().timeIntervalSince1970 * 1000)
        transaction.type = .PUT
        
        if let jsonObject = try? JSONEncoder().encode(object) {
            
            if config.aes256encryptionKey == nil {
                transaction.value = jsonObject
            } else {
                // this data is to be stored encrypted
                if let encKey = config.aes256encryptionKey {
                    let key = encKey.sha256()
                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                    do {
                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                        let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
                        transaction.value = encryptedData
                    } catch {
                        assertionFailure("encryption error: \(error)")
                    }
                }
            }
            
            if let queryableObject = object as? Queryable {
                for kv in queryableObject.queryableItems {
                    if config.hashQueriableProperties == false {
                        // has to be set, equalls only for synced data, soz!
                        assertionFailure("sync providers require hashed parameters to anon the data on the servers")
                    } else {
                        // hash the key and value together so data can be queried, but remains anonymous
                        let keyHash = hashParam(kv.key.data(using: .utf8)!, kv.value)
                        transaction.queryable.append(keyHash)
                    }
                }
            }
            
            return sync(internalId: id, transaction)
            
        }
        
        return false
        
    }
    
    public func delete(key: Data, keyspace: Data) -> Bool {
        
        let id = makeId(key, keyspace)
        let transaction = NetworkRequestTransaction()
        transaction.origin = origin
        transaction.key = key
        transaction.keyspace = keyspace
        transaction.timestamp = Int(Date().timeIntervalSince1970 * 1000)
        transaction.type = .DELETE
        
        return sync(internalId: id, transaction)
        
    }
    
    // unused compliances
    
    @discardableResult
    public func get<T>(key: Data, keyspace: Data) -> T? where T : Decodable, T : Encodable {
        return nil
    }
    
    @discardableResult
    public func query<T>(keyspace: Data, params: [param]?) -> [T] where T : Decodable, T : Encodable {
        return []
    }
    
    @discardableResult
    public func all<T>(keyspace: Data) -> [T] where T : Decodable, T : Encodable {
        return []
    }
    
}

public enum SyncUrgency: String, Codable {
    case superlow = "superlow"
    case low = "low"
    case medium = "medium"
    case high = "high"
    case veryhigh = "veryhigh"
}

fileprivate class KeyspaceSyncSettings: Codable {
    var keyspace: Data?
    var urgency: SyncUrgency?
}

public class SwitchbladeSyncProvider: DataProvider {
    
    fileprivate var provider: DataProvider!
    fileprivate var internalConfig: SwitchbladeConfig!
    public var config : SwitchbladeConfig! {
        get {
            return self.internalConfig
        }
        set {
            if let new = newValue {
                new.hashQueriableProperties = true // this is mandatory for synced data
                if new.aes256encryptionKey == nil {
                    assertionFailure("An encryption key is mandatory for sync data provider.  Make sure one is specified in the switchblade configuration supplied.")
                }
                self.internalConfig = new
                self.provider.config = new
            }
        }
    }
    public weak var blade: Switchblade!
    fileprivate var lock = Mutex()
    fileprivate var accountId: String
    fileprivate var instanceId: String
    
    // internal vars for status
    fileprivate var keyspaceSyncControllers: [Data:SwitchbladeSyncKeyspace] = [:]
    let decoder: JSONDecoder = JSONDecoder()
    fileprivate var keyspaces: [KeyspaceSyncSettings]!
    fileprivate var origin: UUID!
    
    public init(localProvider: DataProvider, accountId: String, instanceId: String) {
        provider = localProvider
        
        self.accountId = accountId
        self.instanceId = instanceId
        
        // create local cache table for changes
        if let spaces: [KeyspaceSyncSettings] = provider.get(key: kSyncedKeyspaces.key(), keyspace: kChangedDataKeyspace) {
            keyspaces = spaces
        } else {
            keyspaces = []
        }
        if let originId: UUID = provider.get(key: kSyncOriginId.key(), keyspace: kChangedDataKeyspace) {
            origin = originId
        } else {
            origin = UUID()
            provider.put(key: kSyncOriginId.key(), keyspace: kChangedDataKeyspace, origin)
        }
        for space in keyspaces {
            let controller = SwitchbladeSyncKeyspace(localProvider: provider, accountId: accountId, instanceId: instanceId, keyspace: space.keyspace!, priority: space.urgency!)
            keyspaceSyncControllers[space.keyspace!] = controller
        }
    }
    
    public func open() throws {
        
    }
    
    public func close() throws {
        
    }
    
    public func addKeyspace(_ keyspace: String, priority: SyncUrgency) {
        lock.mutex {
            if keyspaces.first(where: { $0.keyspace == keyspace.data(using: .utf8)! }) == nil {
                let newKeyspace = KeyspaceSyncSettings()
                newKeyspace.keyspace = keyspace.data(using: .utf8)!
                newKeyspace.urgency = priority
                if provider.put(key: kSyncedKeyspaces.key(), keyspace: kChangedDataKeyspace, keyspaces) {
                    keyspaceSyncControllers[keyspace.data(using: .utf8)!] = SwitchbladeSyncKeyspace(localProvider: provider, accountId: accountId, instanceId: instanceId, keyspace: newKeyspace.keyspace!, priority: priority)
                }
                keyspaces.append(newKeyspace)
            } else {
                
            }
        }
    }
    
    public func removeKeyspace(_ keyspace: String, priority: SyncUrgency) {
        lock.mutex {
            if keyspaces.first(where: { $0.keyspace == keyspace.data(using: .utf8)! }) != nil {
                keyspaces.removeAll(where: { $0.keyspace == keyspace.data(using: .utf8)! })
                if provider.put(key: kSyncedKeyspaces.key(), keyspace: kChangedDataKeyspace, keyspaces) {
                    keyspaceSyncControllers.removeValue(forKey: keyspace.data(using: .utf8)!)
                }
            }
        }
    }
    
    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if provider.put(key: key, keyspace: keyspace, object) {
            // locally persisted, so lets throw this on to the keyspace sync controller, if it's a synced keyspace
            if let controller = keyspaceSyncControllers.first(where: { $0.key == keyspace } )?.value {
                return controller.put(key: key, keyspace: keyspace, object)
            }
            return true
        }
        return false
    }
    
    public func delete(key: Data, keyspace: Data) -> Bool {
        if provider.delete(key: key, keyspace: keyspace) {
            if let controller = keyspaceSyncControllers.first(where: { $0.key == keyspace } )?.value {
                return controller.delete(key: key, keyspace: keyspace)
            }
            return true
        }
        return false
    }
    
    @discardableResult
    public func get<T>(key: Data, keyspace: Data) -> T? where T : Decodable, T : Encodable {
        return provider.get(key: key, keyspace: keyspace)
    }
    
    @discardableResult
    public func query<T>(keyspace: Data, params: [param]?) -> [T] where T : Decodable, T : Encodable {
        return provider.query(keyspace: keyspace, params: params)
    }
    
    @discardableResult
    public func all<T>(keyspace: Data) -> [T] where T : Decodable, T : Encodable {
        return provider.all(keyspace: keyspace)
    }
    
    public func transact(_ mode: transaction) -> Bool {
        provider.transact(mode)
    }
    
}
