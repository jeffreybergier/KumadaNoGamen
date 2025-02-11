//
//  Created by Jeffrey Bergier on 2025/01/18.
//  Copyright © 2025 Saturday Apps.
//
//  This file is part of Teskemon, a macOS App.
//
//  Teskemon is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Teskemon is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Teskemon.  If not, see <http://www.gnu.org/licenses/>.
//

import SwiftUI
import Umbrella
import Model

/// Basic Password Controller for Read Only
@propertyWrapper
public struct PasswordController: DynamicProperty {
  public struct Value {
    public subscript(machine: Machine) -> Password {
      Password.keychainFind(machine: machine)
    }
  }
  public var wrappedValue: Value {
    return .init()
  }
  public init() { }
}

/// Password Controller for Password Management in a Table
@MainActor
@propertyWrapper
public struct PasswordEditController: DynamicProperty {
  
  @MainActor
  public class Value: ObservableObject {
    
    internal var cache: [Machine.Identifier: Password] = [:]
    
    public subscript(machine: Machine) -> Password {
      set {
        self.objectWillChange.send()
        self.cache[machine.id] = newValue
      }
      get {
        if let password = self.cache[machine.id] { return password }
        let password = Password.keychainFind(machine: machine)
        self.cache[machine.id] = password
        return password
      }
    }
    
    public func bind(_ machine: Machine) -> Binding<Password> {
      return Binding {
        return self[machine]
      } set: {
        self[machine] = $0
      }
    }
    
    public func deletePassword(for machine: Machine) {
      do {
        try Password.keychainDelete(machine: machine)
        self.objectWillChange.send()
        self.cache.removeValue(forKey: machine.id)
      } catch {
        let password = self.bind(machine)
        password.wrappedValue.status = .error(error)
      }
    }
    
    public func resetPassword(for machine: Machine) {
      self.objectWillChange.send()
      self.cache.removeValue(forKey: machine.id)
    }
    
    public func savePassword(for machine: Machine) {
      let password = self.bind(machine)
      do {
        switch password.wrappedValue.inKeychain {
        case false:
          let toSave = try password.wrappedValue.valueForSaving()
          try Password.keychainAdd(item: toSave)
        case true:
          let item = password.wrappedValue.valueForUpdating()
          let newValues = try password.wrappedValue.valueForUpdate()
          try Password.keychainUpdate(item: item, newValues: newValues)
        }
        password.wrappedValue.inKeychain = true
        password.wrappedValue.status = .isViewing
        return
      } catch {
        password.wrappedValue.status = .error(error)
        return
      }
    }
  }
    
  @StateObject private var storage = Value()
  
  public var wrappedValue: Value {
    self.storage
  }
  
  public init() { }
}

extension Password {
  
  internal static func keychainAdd(item: Descriptor) throws(Password.Error) {
    let status = SecItemAdd(item as CFDictionary, nil)
    guard status == errSecSuccess else { throw .keychain(status) }
    return
  }
  
  internal static func keychainUpdate(item:      Descriptor,
                                      newValues: Descriptor) throws(Password.Error)
  {
    let status = SecItemUpdate(item      as CFDictionary,
                               newValues as CFDictionary)
    guard status == errSecSuccess else { throw .keychain(status) }
    return
  }
  
  private static func keychainFind(item: Descriptor) throws(Password.Error) -> Password {
    var output: CFTypeRef?
    let status = SecItemCopyMatching(item as CFDictionary, &output)
    switch status {
    case errSecSuccess:
      return Password(from: output as! Descriptor)
    default:
      throw .keychain(status)
    }
  }
  
  internal static func keychainFind(machine: Machine) -> Password {
    let descriptor: Password.Descriptor = [
      kSecClass:            Password.defaultClass,
      kSecAttrCreator:      Password.defaultCreator,
      kSecMatchLimit:       kSecMatchLimitOne,
      kSecReturnData:       true,
      kSecReturnAttributes: true,
      kSecAttrServer:       machine.host,
    ]
    
    do {
      var output = try Password.keychainFind(item: descriptor)
      output.inKeychain = true
      if output.app_server == machine.host { return output }
      output.status = .error(.machineDataIncorrect)
      return output
    } catch {
      switch error {
      case .keychain(let status) where status == errSecItemNotFound:
        var output = Password()
        output.app_server = machine.host
        output.app_label  = "\(machine.host) (\(machine.name)<\(machine.id.rawValue)>)"
        return output
      default:
        var output = Password()
        output.status = .error(error)
        return output
      }
    }
  }
  
  internal static func keychainDelete(machine: Machine) throws(Password.Error) {
    let descriptor: Password.Descriptor = [
      kSecClass:            Password.defaultClass,
      kSecAttrCreator:      Password.defaultCreator,
      kSecAttrServer:       machine.host,
    ]
    
    let status = SecItemDelete(descriptor as CFDictionary)
    guard status == errSecSuccess else { throw .keychain(status) }
    return
  }
  
}
