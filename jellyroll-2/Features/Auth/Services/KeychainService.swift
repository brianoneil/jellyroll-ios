import Foundation
import Security

enum KeychainError: Error {
    case itemNotFound
    case duplicateItem
    case invalidItemFormat
    case unexpectedStatus(OSStatus)
}

class KeychainService {
    static let shared = KeychainService()
    
    private init() {}
    
    // MARK: - Server Configuration
    
    func saveServerConfiguration(_ config: ServerConfiguration) throws {
        let data = try JSONEncoder().encode(config)
        try saveToKeychain(data, forKey: "server_config")
    }
    
    func loadServerConfiguration() throws -> ServerConfiguration? {
        guard let data = try loadFromKeychain(forKey: "server_config") else { return nil }
        return try JSONDecoder().decode(ServerConfiguration.self, from: data)
    }
    
    // MARK: - Authentication Token
    
    func saveAuthToken(_ token: AuthenticationToken) throws {
        let data = try JSONEncoder().encode(token)
        try saveToKeychain(data, forKey: "auth_token")
    }
    
    func loadAuthToken() throws -> AuthenticationToken? {
        guard let data = try loadFromKeychain(forKey: "auth_token") else { return nil }
        return try JSONDecoder().decode(AuthenticationToken.self, from: data)
    }
    
    // MARK: - Private Helpers
    
    private func saveToKeychain(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try updateInKeychain(data, forKey: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    private func loadFromKeychain(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
        
        return result as? Data
    }
    
    private func updateInKeychain(_ data: Data, forKey key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    func clearAll() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
} 