/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
 *
 * This file is part of linphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

// Core Extension provides a set of utilies to manage automatically a LinphoneCore no matter if it is from App or an extension.
// It is based on a singleton pattern and adds.

import UIKit
import linphonesw

struct CoreError: Error {
	let message: String
	init(_ message: String) {
		self.message = message
	}
	public var localizedDescription: String {
		return message
	}
}

extension Core {
	
	public static func runsInsideExtension() -> Bool { // Tells wether it is run inside app extension or the main app.
		let bundleUrl: URL = Bundle.main.bundleURL
		let bundlePathExtension: String = bundleUrl.pathExtension
		return bundlePathExtension == "appex"
	}
	
}

// SOCKS5 is an application transport, not a VPN or an embedded proxy server.
import Security

enum Socks5Settings {
 // Keep intent outside provisionable LinphoneConfig: a downloaded/reset config
 // must never turn a user-required proxy into an implicit direct connection.
 static func preferences() throws -> UserDefaults {
  guard let group = Bundle.main.object(forInfoDictionaryKey: "APP_GROUP_NAME") as? String,
        let defaults = UserDefaults(suiteName: group) else {
   throw CoreError("Shared proxy preferences unavailable. Core remains stopped.")
  }
  return defaults
 }
 struct Credentials: Codable { let username: String; let password: String }
 private static let service = "org.linphone.socks5.credentials"
 private static var query: [String: Any] {
  [kSecClass as String: kSecClassGenericPassword,
   kSecAttrService as String: service, kSecAttrAccount as String: "proxy"]
 }
 static func readCredentials() throws -> Credentials {
  var request = query
  request[kSecReturnData as String] = true
  request[kSecMatchLimit as String] = kSecMatchLimitOne
  var item: CFTypeRef?
  guard SecItemCopyMatching(request as CFDictionary, &item) == errSecSuccess,
        let data = item as? Data else {
   throw CoreError("SOCKS5 credentials unavailable. Core remains stopped.")
  }
  return try JSONDecoder().decode(Credentials.self, from: data)
 }
 static func saveCredentials(username: String, password: String) throws {
  guard username.utf8.count <= 255, password.utf8.count <= 255,
        username.isEmpty == password.isEmpty,
        !username.contains("\0"), !password.contains("\0") else {
   throw CoreError("SOCKS5 username and password must both be empty or both be 1–255 UTF-8 bytes.")
  }
  let data = try JSONEncoder().encode(Credentials(username: username, password: password))
  let values: [String: Any] = [kSecValueData as String: data,
    kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly]
  let status = SecItemUpdate(query as CFDictionary, values as CFDictionary)
  if status == errSecItemNotFound {
   var insert = query
   values.forEach { insert[$0.key] = $0.value }
   guard SecItemAdd(insert as CFDictionary, nil) == errSecSuccess else {
    throw CoreError("Unable to save SOCKS5 credentials in Keychain.")
   }
  } else if status != errSecSuccess {
   throw CoreError("Unable to update SOCKS5 credentials in Keychain.")
  }
 }
 static func removeCredentials() { SecItemDelete(query as CFDictionary) }
}

extension Core {
 // All main-app start/restart paths must use this entry, including provisioning.
 // The SDK independently checks persisted intent when a shared Core is created.
 func startWithSocks5Policy() throws {
  if globalState == .On { return }
  guard let config = config else { throw CoreError("Core configuration unavailable.") }
  let preferences = try Socks5Settings.preferences()
  let required = preferences.bool(forKey: "socks5.required") || config.getBool(section: "socks5", key: "required", defaultValue: false)
  if required { preferences.set(true, forKey: "socks5.required") }
  if required {
   guard !Core.runsInsideExtension() else {
    throw CoreError("SOCKS5 notification-extension networking is unsupported.")
   }
#if LINPHONE_SOCKS5_SDK
   let secret = try Socks5Settings.readCredentials()
   let configuredHost: String? = preferences.string(forKey: "socks5.host") ?? config.getString(section: "socks5", key: "host", defaultString: nil)
   guard let host = configuredHost, !host.isEmpty else {
    throw CoreError("SOCKS5 proxy address is missing.")
   }
   try setSocks5Proxy(host: host, port: preferences.object(forKey: "socks5.port") == nil ? config.getInt(section: "socks5", key: "port", defaultValue: 0) : preferences.integer(forKey: "socks5.port"),
                     username: secret.username.isEmpty ? nil : secret.username,
                     password: secret.password.isEmpty ? nil : secret.password)
#else
   throw CoreError("SOCKS5 requires the locally built fork SDK. Official SDK startup is blocked.")
#endif
  } else {
#if LINPHONE_SOCKS5_SDK
   try setSocks5Proxy(host: nil, port: 0, username: nil, password: nil)
#endif
  }
  try start()
 }
}
