//
//  ZestyDBProvider.swift
//  Switchblade
//
//  A DataProvider that talks to a ZestyDB server over its REST API.
//
//  ZestyDB is a standalone distributed key/value server exposing a REST
//  interface for put/get/delete/query/all/ids. Each record lives at
//  `{database}/{partition}/{keyspace}/{id}`; the JSON document itself is
//  the value. This provider maps Switchblade's partition/keyspace/key model
//  directly onto those segments and shares a single authenticated session
//  token across all requests (and across provider instances).
//

import Foundation
import Dispatch

public class ZestyDBProvider: DataProvider {

    public var config: SwitchbladeConfig!
    public weak var blade: Switchblade!

    // Connection identity
    private let baseURL: URL
    private let database: String
    private let username: String
    private let password: String

    private let lock = Mutex()
    private let session: URLSession
    private let decoder = JSONDecoder()

    // Session tokens are shared between every provider pointing at the same
    // server/user so they do not each open a fresh login session. Keyed by
    // "baseURL|username".
    private static let tokenCacheLock = Mutex()
    private static var tokenCache: [String: String] = [:]

    /// - Parameters:
    ///   - url: base URL of the ZestyDB server (e.g. `http://host:8123`).
    ///   - database: the ZestyDB database name every operation targets.
    ///   - username: account used to authenticate (`POST /admin/login`).
    ///   - password: account password.
    public init(url: URL, database: String, username: String, password: String) {
        self.baseURL = url
        self.database = database
        self.username = username
        self.password = password

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: configuration)
    }

    // MARK: - Lifecycle

    public func open() throws {
        // Authenticate eagerly so an unreachable server or bad credentials
        // surface at init time rather than on the first read/write.
        _ = try obtainToken()
    }

    public func close() throws {
        // Nothing to tear down; the shared session token stays cached for
        // other providers or a later reopen.
    }

    public func transact(_ mode: transaction) -> Bool {
        // ZestyDB's REST API is stateless and has no server-side transaction
        // concept, so transactions are stubbed out.
        return true
    }

    // MARK: - DataProvider

    @discardableResult
    public func put<T>(partition: String, key: String, keyspace: String, ttl: Int, filter: [String : String]?, _ object: T) -> Bool where T : Decodable, T : Encodable {
        guard let body = try? JSONEncoder().encode(object) else {
            return false
        }
        let query = ttl >= 0 ? "?ttl=\(ttl)" : ""
        let path = dataPath(partition: partition, keyspace: keyspace, suffix: key) + query
        let result = request("PUT", path, body: body)
        return (200..<300).contains(result.status)
    }

    @discardableResult
    public func delete(partition: String, key: String, keyspace: String) -> Bool {
        let path = dataPath(partition: partition, keyspace: keyspace, suffix: key)
        let result = request("DELETE", path)
        return (200..<300).contains(result.status)
    }

    @discardableResult
    public func get<T>(partition: String, key: String, keyspace: String) -> T? where T : Decodable, T : Encodable {
        let path = dataPath(partition: partition, keyspace: keyspace, suffix: key)
        let result = request("GET", path)
        guard (200..<300).contains(result.status) else {
            return nil
        }
        return try? decoder.decode(T.self, from: result.data)
    }

    @discardableResult
    public func query<T>(partition: String, keyspace: String, filter: [String : String]?, map: ((T) -> Bool)) -> [T] where T : Decodable, T : Encodable {
        // The server has no predicate push-down beyond structured filters;
        // the Switchblade `map` closure is applied client-side.
        return all(partition: partition, keyspace: keyspace, filter: filter)
            .filter(map)
    }

    @discardableResult
    public func all<T>(partition: String, keyspace: String, filter: [String : String]?) -> [T] where T : Decodable, T : Encodable {
        let path = dataPath(partition: partition, keyspace: keyspace, suffix: "all")
        let result = request("POST", path, body: structuredFilters(filter))
        guard (200..<300).contains(result.status) else {
            return []
        }
        return (try? decoder.decode([T].self, from: result.data)) ?? []
    }

    public func iterate<T>(partition: String, keyspace: String, filter: [String : String]?, iterator: ((T) -> Void)) where T : Decodable, T : Encodable {
        // ZestyDB exposes no streaming endpoint; fall back to a bulk read.
        for object: T in all(partition: partition, keyspace: keyspace, filter: filter) {
            iterator(object)
        }
    }

    public func migrate<FromType, ToType>(from: FromType.Type, to: ToType.Type, migration: @escaping ((FromType) -> ToType?)) where FromType : SchemaVersioned, ToType : SchemaVersioned {
        // Schema migration is a local-SQLite concept; ZestyDB has none.
        // Stubbed out.
    }

    @discardableResult
    public func ids(partition: String, keyspace: String, filter: [String : String]?) -> [String] {
        let path = dataPath(partition: partition, keyspace: keyspace, suffix: "ids")
        let result = request("POST", path, body: structuredFilters(filter))
        guard (200..<300).contains(result.status) else {
            return []
        }
        return (try? decoder.decode([String].self, from: result.data)) ?? []
    }

    // MARK: - Routing helpers

    private func dataPath(partition: String, keyspace: String, suffix: String) -> String {
        return "/data/\(encode(database))/\(encode(partition))/\(encode(keyspace))/\(encode(suffix))"
    }

    private func encode(_ value: String) -> String {
        let allowed = CharacterSet(charactersIn:
            "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        return value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }

    // MARK: - Auth

    private var tokenCacheKey: String {
        return "\(baseURL.absoluteString)|\(username)"
    }

    private func obtainToken() throws -> String {
        // Reuse a cached token when one is already shared for this server/user.
        if let cached = ZestyDBProvider.tokenCacheLock.mutex({ () -> String? in
            ZestyDBProvider.tokenCache[tokenCacheKey]
        }) {
            return cached
        }

        let body = try JSONSerialization.data(withJSONObject: [
            "username": username,
            "password": password
        ])
        let result = send("POST", "/admin/login", body: body, token: nil)
        guard (200..<300).contains(result.status),
              let object = (try? JSONSerialization.jsonObject(with: result.data)) as? [String: Any],
              let token = object["token"] as? String else {
            throw DatabaseError.Init(.UnableToConnectToServer)
        }

        ZestyDBProvider.tokenCacheLock.mutex {
            ZestyDBProvider.tokenCache[tokenCacheKey] = token
        }
        return token
    }

    private func invalidateToken() {
        ZestyDBProvider.tokenCacheLock.mutex {
            _ = ZestyDBProvider.tokenCache.removeValue(forKey: tokenCacheKey)
        }
    }

    // MARK: - HTTP plumbing

    private struct HTTPResult {
        let status: Int
        let data: Data
    }

    /// Sends a request with the shared auth token, transparently
    /// re-authenticating once if the server rejects the token (e.g. a
    /// short-lived session that has since expired).
    private func request(_ method: String, _ path: String, body: Data? = nil) -> HTTPResult {
        var token = try? obtainToken()
        var result = send(method, path, body: body, token: token)
        if result.status == 401 {
            invalidateToken()
            token = try? obtainToken()
            result = send(method, path, body: body, token: token)
        }
        return result
    }

    private func send(_ method: String, _ path: String, body: Data?, token: String?) -> HTTPResult {
        guard let url = url(forPath: path) else {
            return HTTPResult(status: -1, data: Data())
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token = token {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        let semaphore = DispatchSemaphore(value: 0)
        var status = -1
        var data = Data()
        session.dataTask(with: request) { responseData, response, _ in
            data = responseData ?? Data()
            if let http = response as? HTTPURLResponse {
                status = http.statusCode
            }
            semaphore.signal()
        }.resume()
        semaphore.wait()

        return HTTPResult(status: status, data: data)
    }

    private func url(forPath path: String) -> URL? {
        let base = baseURL.absoluteString.hasSuffix("/")
            ? String(baseURL.absoluteString.dropLast())
            : baseURL.absoluteString
        return URL(string: base + path)
    }

    // MARK: - Filters

    /// Converts Switchblade's `[String:String]` equality filters into
    /// ZestyDB's structured filter array `{"filters":[{"key","operator",
    /// "value"}]}`. Values are heuristically re-typed (bool/number/null) so
    /// numeric and boolean filters match the stored JSON types.
    private func structuredFilters(_ filter: [String : String]?) -> Data? {
        guard let filter = filter, !filter.isEmpty else {
            return nil
        }
        let filters: [[String: Any]] = filter.map { key, value in
            ["key": key, "operator": "eq", "value": typedValue(value)]
        }
        return try? JSONSerialization.data(withJSONObject: ["filters": filters])
    }

    private func typedValue(_ value: String) -> Any {
        switch value {
        case "true": return true
        case "false": return false
        case "null": return NSNull()
        default:
            if let int = Int(value) { return int }
            if let double = Double(value) { return double }
            return value
        }
    }

}
