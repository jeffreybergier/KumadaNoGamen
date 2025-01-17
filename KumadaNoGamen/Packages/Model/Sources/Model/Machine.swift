//
//  Created by Jeffrey Bergier on 2025/01/12.
//  Copyright © 2025 Saturday Apps.
//
//  This file is part of KumadaNoGamen, a macOS App.
//
//  KumadaNoGamen is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  KumadaNoGamen is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with KumadaNoGamen.  If not, see <http://www.gnu.org/licenses/>.
//

import Foundation

public struct Machine: Codable, Sendable, Identifiable {
  
  // Machine Conformance
  public let id: MachineIdentifier
  public let name: String
  public let url: String
  public let os: String?
  public let kind: MachineKind
  public let relay: MachineRelay
  public let activity: MachineActivity?
  public let subnetRoutes: [Machine]?
  public let extraInfo: MachineExtraInfo?
  
  /// Init for advertised subnets
  internal init(address: Address, hostName: String, hostID: MachineIdentifier, selfID: MachineIdentifier) {
    self.id   = .init(rawValue: selfID.rawValue + ":" + address.rawValue)
    self.name = address.rawValue
    self.url  = address.rawValue
    self.os   = nil
    self.kind = hostID == selfID ? .meSubnet : .remoteSubnet
    self.relay = .route(id: hostID, name: hostName)
    self.activity = nil
    self.subnetRoutes = nil
    self.extraInfo = nil
  }
  
  /// Init for JSON from the Tailscale CLI
  internal init(_ model: JSON.MachineCLI, selfID: MachineIdentifier) {
    self.id       = .init(rawValue: model.ID)
    self.name     = model.HostName
    self.url      = model.DNSName
    self.os       = model.OS
    self.kind     = model.ID == selfID.rawValue ? .meHost : .remoteHost
    self.relay    = .relay(model.Relay)
    self.activity = .init(isOnline: model.Online,
                         isActive: model.Active,
                         rxBytes: Int64(model.RxBytes),
                         txBytes: Int64(model.TxBytes),
                         lastSeen: model.LastSeen.flatMap(df.date(from:)))
    
    let subnetRoutes: [Machine]? = model.PrimaryRoutes?.flatMap { subnet in
      Subnet(rawValue: subnet).explodeAddresses().map { address in
        Machine(address: address,
                       hostName: model.HostName,
                       hostID: .init(rawValue: model.ID),
                       selfID: selfID)
      }
    }
    self.subnetRoutes = (subnetRoutes?.isEmpty ?? true) ? nil : subnetRoutes
    
    self.extraInfo = .init(
      publicKey: model.PublicKey,
      keyExpiry: model.KeyExpiry.flatMap(df.date(from:)),
      isExitNode: model.ExitNode,
      userID: model.UserID,
      tailscaleIPs: model.TailscaleIPs.map { Address(rawValue: $0) },
      created: df.date(from: model.Created)!,
      lastWrite: model.LastWrite.flatMap(df.date(from:)),
      lastHandshake: model.LastWrite.flatMap(df.date(from:)),
      inNetworkMap: model.InNetworkMap,
      inMagicSock: model.InMagicSock,
      inEngine: model.InEngine
    )
  }
}

public struct MachineExtraInfo: Codable, Sendable, Hashable {
  // Information
  public let publicKey: String
  public let keyExpiry: Date?
  public let isExitNode: Bool
  public let userID: Int
  
  // Network
  public let tailscaleIPs: [Address]
  
  // Timestamps
  public let created: Date
  public let lastWrite: Date?
  public let lastHandshake: Date?
  // Status
  public let inNetworkMap: Bool
  public let inMagicSock: Bool
  public let inEngine: Bool
}

public struct MachineIdentifier: Codable, Sendable, Hashable, Identifiable, RawRepresentable {
  public var id: String { return self.rawValue }
  public let rawValue: String
  public init(rawValue: String) {
    self.rawValue = rawValue
  }
}

public struct MachineActivity: Codable, Sendable, Hashable {
  public let isOnline: Bool
  public let isActive: Bool
  public let rxBytes: Int64
  public let txBytes: Int64
  public let lastSeen: Date?
}

public enum MachineKind: Codable, Sendable, Hashable {
  case meHost, remoteHost, meSubnet, remoteSubnet
}

public enum MachineRelay: Codable, Sendable, Hashable {
  case relay(String)
  case route(id: MachineIdentifier, name: String)
  public var displayName: String {
    switch self {
    case .relay(let name): return name
    case .route(_, let name): return name
    }
  }
}

public struct User: Codable, Sendable {
  public struct Identifier: Codable, Sendable, Hashable, Identifiable, RawRepresentable {
    public var id: Int { return self.rawValue }
    public let rawValue: Int
    public init(rawValue: Int) {
      self.rawValue = rawValue
    }
  }
  public let id: Identifier
  public let loginName: String
  public let displayName: String
  public let profilePicURL: String
  public let roles: [String]
  
  public enum CodingKeys: String, CodingKey {
    case id = "ID"
    case loginName = "LoginName"
    case displayName = "DisplayName"
    case profilePicURL = "ProfilePicURL"
    case roles = "Roles"
  }
}

public struct Tailscale: Codable, Sendable {
  // Status
  public let version: String
  public let versionUpToDate: Bool
  public let tunnelingEnabled: Bool
  public let backendState: String
  public let haveNodeKey: Bool
  public let health: [String]
  // Network
  public let magicDNSSuffix: String
  public let currentTailnet: Tailnet?
  // Identification
  public let selfNodeID: MachineIdentifier
  public let selfUserID: User.Identifier
}

public struct Tailnet: Codable, Sendable {
  public let name: String
  public let magicDNSSuffix: String
  public let magicDNSEnabled: Bool
  
  public enum CodingKeys: String, CodingKey {
    case name = "Name"
    case magicDNSSuffix = "MagicDNSSuffix"
    case magicDNSEnabled = "MagicDNSEnabled"
  }
}
