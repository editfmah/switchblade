//
//  UserDefaultsProvider.swift
//  Switchblade
//
//  Created by Adrian Herridge on 08/02/2021.
//

import Foundation
import Dispatch
import CryptoSwift

public class UserDefaultsProvider: DataProvider, DataProviderPrivate {
    
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
    
    fileprivate func makeId(_ key: Data,_ keyspace: Data) -> String {
        var id = Data(key)
        id.append(keyspace)
        return "Switchblade_\(id.sha224().toHexString())"
    }
    
    public func transact(_ mode: transaction) -> Bool {
        return true
    }

    public func put<T>(key: Data, keyspace: Data, _ object: T) -> Bool where T : Decodable, T : Encodable {
        
        if let jsonObject = try? JSONEncoder().encode(object) {
            let id = makeId(key, keyspace)
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
    
    func put(key: Data, keyspace: Data, object: Data?, queryKeys: [Data]?) -> Bool {
        put(key: key, keyspace: keyspace, object)
    }
    
    public func delete(key: Data, keyspace: Data) -> Bool {
        let id = makeId(key, keyspace)
        defaults.removeObject(forKey: id)
        return true
    }
    
    @discardableResult
    public func get<T>(key: Data, keyspace: Data) -> T? where T : Decodable, T : Encodable {
        let id = makeId(key, keyspace)
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
    
    @discardableResult
    public func query<T>(keyspace: Data, params: [param]?) -> [T] where T : Decodable, T : Encodable {
        let results: [T] = []
        return results
    }
    
    @discardableResult
    public func all<T>(keyspace: Data) -> [T] where T : Decodable, T : Encodable {
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
    
}

