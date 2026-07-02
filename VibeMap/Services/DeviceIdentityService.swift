import CryptoKit
import Foundation
import Security

protocol DeviceIdentifying {
    func deviceIDHash() -> String
}

final class DeviceIdentityService: DeviceIdentifying {
    private let defaults: UserDefaults
    private let storageKey = "vibe-map.anonymous-device-id"
    private let keychainService = "com.brianhakel.vibemap"
    private let keychainAccount = "anonymous-device-id"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func deviceIDHash() -> String {
        let rawID = anonymousDeviceID()
        let digest = SHA256.hash(data: Data(rawID.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func anonymousDeviceID() -> String {
        if let existing = keychainDeviceID() {
            if defaults.string(forKey: storageKey) != existing {
                defaults.set(existing, forKey: storageKey)
            }
            return existing
        }

        if let existing = defaults.string(forKey: storageKey), !existing.isEmpty {
            saveDeviceIDToKeychain(existing)
            return existing
        }

        let newID = UUID().uuidString
        saveDeviceIDToKeychain(newID)
        defaults.set(newID, forKey: storageKey)
        return newID
    }

    private func keychainDeviceID() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8),
              !value.isEmpty else {
            return nil
        }

        return value
    }

    private func saveDeviceIDToKeychain(_ value: String) {
        let baseQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount
        ]

        SecItemDelete(baseQuery as CFDictionary)

        var item = baseQuery
        item[kSecValueData as String] = Data(value.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly

        SecItemAdd(item as CFDictionary, nil)
    }
}
