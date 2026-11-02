import Foundation
import Security

enum SecretStore {
    static let service = (Bundle.main.bundleIdentifier ?? "com.fishbot.assistant.ios") + ".api-keys"
    static func query(_ slot: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword, kSecAttrService as String: service, kSecAttrAccount as String: slot]
    }
    static func get(_ slot: String) throws -> String {
        var request = query(slot)
        request[kSecReturnData as String] = true
        request[kSecMatchLimit as String] = kSecMatchLimitOne
        var value: CFTypeRef?
        let status = SecItemCopyMatching(request as CFDictionary, &value)
        if status == errSecItemNotFound { return "" }
        guard status == errSecSuccess, let data = value as? Data else { throw LocalError.message("钥匙串暂不可用，请解锁手机后重试。") }
        return String(data: data, encoding: .utf8) ?? ""
    }
    static func set(_ slot: String, _ value: String) throws {
        let base = query(slot)
        if value.isEmpty {
            let status = SecItemDelete(base as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else { throw LocalError.message("无法移除已保存的 Key。") }
            return
        }
        let fields: [String: Any] = [kSecValueData as String: Data(value.utf8), kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly]
        var status = SecItemUpdate(base as CFDictionary, fields as CFDictionary)
        if status == errSecItemNotFound { status = SecItemAdd(base.merging(fields) { _, new in new } as CFDictionary, nil) }
        guard status == errSecSuccess else { throw LocalError.message("Key 保存失败，请解锁手机后重试。") }
    }
}

enum LocalError: Error {
    case message(String)
    var message: String { if case let .message(value) = self { return value }; return "操作未能完成。" }
}
