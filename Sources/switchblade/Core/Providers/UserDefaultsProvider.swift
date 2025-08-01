//
//  UserDefaultsProvider.swift
//  Switchblade
//
//  Created by Adrian Herridge on 08/02/2021.
//

#if canImport(Foundation) && !os(Linux)

import Foundation
import Dispatch
import CryptoSwift

fileprivate extension Data {
    var bytes : [UInt8]{
        return [UInt8](self)
    }
}

public class UserDefaultsProvider: DataProvider {
    
    public var config: SwitchbladeConfig!
    public weak var blade: Switchblade!
    fileprivate var lock = Mutex()
    
    var defaults = UserDefaults.standard
    let decoder: JSONDecoder = JSONDecoder()
    
    public init()  {
        // regardless of the comment, it absolutely is neccesary!
        defaults.synchronize()
    }
    
    public func open() throws {
    }
    
    public func close() throws {
        defaults.synchronize()
    }
    
    fileprivate func makeId(_ key: String) -> String {
        return "Switchblade_\(key.sha224())"
    }
    
    public func transact(_ mode: transaction) -> Bool {
        return true
    }

    public func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: ((FromType) -> ToType?)) where FromType : SchemaVersioned, ToType : SchemaVersioned {
        
    }
    
    public func ids(partition: String, keyspace: String, filter: [String : String]?) -> [String] {
        var results: [String] = []
        for (id, _) in defaults.dictionaryRepresentation() {
            results.append(id)
        }
        return results
    }
    
    public func put<T>(partition: String, key: String, keyspace: String, ttl: Int, filter: [String:String]?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        if let jsonObject = try? JSONEncoder().encode(object) {
            let id = makeId(key)
            if config.aes256encryptionKey == nil {
                defaults.setValue(jsonObject, forKey: id)
            } else {
                // this data is to be stored encrypted
                if let encKey = config.aes256encryptionKey {
                    let key = encKey.sha256()
                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                    do {
                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                        let encryptedData = Data(try aes.encrypt(jsonObject.bytes))
                        defaults.setValue(encryptedData, forKey: id)
                    } catch {
                        print("encryption error: \(error)")
                    }
                }
            }
        }
        return true
    }
    
    public func delete(partition: String, key: String, keyspace: String) -> Bool {
        let id = makeId(key)
        defaults.removeObject(forKey: id)
        return true
    }
    
    public func get<T>(partition: String, key: String, keyspace: String) -> T? where T : Decodable, T : Encodable {
        let id = makeId(key)
        if config.aes256encryptionKey == nil {
            if let data = defaults.data(forKey: id), let object = try? decoder.decode(T.self, from: data) {
                return object
            }
        } else {
            if let data = defaults.data(forKey: id), let encKey = config.aes256encryptionKey {
                let key = encKey.sha256()
                let iv = (encKey + Data(kSaltValue.bytes)).md5()
                do {
                    let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                    let decryptedBytes = try aes.decrypt(data.bytes)
                    let decryptedData = Data(decryptedBytes)
                    let object = try decoder.decode(T.self, from: decryptedData)
                    return object
                } catch {
                    print("encryption error: \(error)")
                }
            }
        }
        return nil
    }

    
public func query<T>(partition: String, keyspace: String, filter: [String : String]?, map: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        var results: [T] = []
        for o: T in all(partition: partition, keyspace: keyspace, filter: filter) {
            if map(o) {
                results.append(o)
            }
        }
        return results
    }
    
public func all<T>(partition: String, keyspace: String, filter: [String : String]?) -> [T] where T : Decodable, T : Encodable {
        
        var results: [T] = []
        for (id, _) in defaults.dictionaryRepresentation() {
            if config.aes256encryptionKey == nil {
                if let data = defaults.data(forKey: id), let object = try? decoder.decode(T.self, from: data) {
                    results.append(object)
                }
            } else {
                if let data = defaults.data(forKey: id), let encKey = config.aes256encryptionKey {
                    let key = encKey.sha256()
                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                    do {
                        
                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                        let decryptedBytes = try aes.decrypt(data.bytes)
                        let decryptedData = Data(decryptedBytes)
                        let object = try decoder.decode(T.self, from: decryptedData)
                        
                        results.append(object)
                        
                    } catch {
                        print("encryption error: \(error)")
                    }
                }
            }
        }
        return results
    }
    
    public func iterate<T>(partition: String, keyspace: String, filter: [String : String]?, iterator: ((T) -> Void)) where T : Decodable, T : Encodable {
        
        for (id, _) in defaults.dictionaryRepresentation() {
            if config.aes256encryptionKey == nil {
                if let data = defaults.data(forKey: id), let object = try? decoder.decode(T.self, from: data) {
                    iterator(object)
                }
            } else {
                if let data = defaults.data(forKey: id), let encKey = config.aes256encryptionKey {
                    let key = encKey.sha256()
                    let iv = (encKey + Data(kSaltValue.bytes)).md5()
                    do {
                        
                        let aes = try AES(key: key.bytes, blockMode: CBC(iv: iv.bytes))
                        let decryptedBytes = try aes.decrypt(data.bytes)
                        let decryptedData = Data(decryptedBytes)
                        let object = try decoder.decode(T.self, from: decryptedData)
                        
                        iterator(object)
                        
                    } catch {
                        print("encryption error: \(error)")
                    }
                }
            }
        }
        
    }
    
}

#endif
