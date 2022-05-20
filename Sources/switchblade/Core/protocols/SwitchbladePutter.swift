//
//  SwitchbladeSetter.swift
//  Switchblade
//
//  Created by Adrian Herridge on 21/09/2020.
//

import Foundation

public protocol SwitchbadePutter {
    @discardableResult func put<T:Codable>(_ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(ttl: Int?, _ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(keyspace: String, _ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(keyspace: String, ttl: Int?, _ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(key: PrimaryKeyType, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(key: PrimaryKeyType, ttl: Int?, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(key: PrimaryKeyType, keyspace: String, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(key: PrimaryKeyType, keyspace: String, ttl: Int?, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(_ compositeKeys: [CompositeComponent], _ object: T) -> Bool
    @discardableResult func put<T:Codable>(_ compositeKeys: [CompositeComponent], ttl: Int?, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(partition: String, ttl: Int?, _ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(partition: String, keyspace: String, ttl: Int?, _ object: T) -> Bool where T: Identifiable
    @discardableResult func put<T:Codable>(partition: String, key: PrimaryKeyType, ttl: Int?, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(partition: String, key: PrimaryKeyType, keyspace: String, ttl: Int?, _ object: T) -> Bool
    @discardableResult func put<T:Codable>(partition: String, _ compositeKeys: [CompositeComponent], ttl: Int?, _ object: T) -> Bool
}
