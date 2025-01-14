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

public struct Tailscale: Codable, Sendable {
  
  public struct Refresh: Codable, Sendable {
    public let tailscale: Tailscale
    public let machines: [Machine.Identifier: Machine]
    public let users: [Machine.Identifier: User]
    public static func new(data: Data) throws -> Refresh {
      return try JSONDecoder().decode(JSON.TailscaleCLI.self, from: data).clean()
    }
  }
  
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
  public let selfNodeID: Machine.Identifier
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

public struct Machine: Codable, Sendable, Identifiable {
  public struct Identifier: Codable, Sendable, Hashable, Identifiable, RawRepresentable {
    public var id: String { return self.rawValue }
    public let rawValue: String
    public init(rawValue: String) {
      self.rawValue = rawValue
    }
  }
  // Information
  public let id: Identifier
  public let publicKey: String
  public let keyExpiry: Date?
  public let hostname: String
  public let url: String
  public let os: String
  public let userID: Int
  public let isExitNode: Bool
  // Network
  public let tailscaleIPs: [Address]
  public let subnetRoutes: [Subnet]
  public let region: String
  // Traffic
  public let isActive: Bool
  public let rxBytes: Int64
  public let txBytes: Int64
  // Timestamps
  public let created: Date
  public let lastWrite: Date?
  public let lastSeen: Date?
  public let lastHandshake: Date?
  // Status
  public let isOnline: Bool
  public let inNetworkMap: Bool
  public let inMagicSock: Bool
  public let inEngine: Bool
  // Services
  public var serviceStatus: [Service: Bool] = [:]
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

public struct Service: Codable, Sendable, Hashable, Identifiable {
  
  public enum Status: Codable, Sendable, Hashable {
    case unknown
    case error
    case online
    case offline
    case processing
  }
  
  public static let `default`: [Service] = {
    return [
      Service(name: "AFP", protocol: "afp", port: 548),
      Service(name: "SSH", protocol: "ssh", port: 22),
      Service(name: "SMB", protocol: "smb", port: 445),
      Service(name: "RDP", protocol: "rdp", port: 3389),
      Service(name: "VNC", protocol: "vnc", port: 5900),
    ]
  }()
  
  public var name: String
  public var `protocol`: String
  public var port: Int
  public var id: Int { self.port }
}

internal enum JSON {
  
  internal struct TailscaleCLI: Codable, Sendable {
    internal let Version: String
    internal let TUN: Bool
    internal let BackendState: String
    internal let HaveNodeKey: Bool
    internal let AuthURL: String?
    internal let TailscaleIPs: [String]?
    internal let `Self`: MachineCLI
    internal let Health: [String]
    internal let MagicDNSSuffix: String
    internal let CurrentTailnet: Tailnet?
    internal let CertDomains: [String]?
    internal let Peer: [String: MachineCLI]?
    internal let User: [String: User]?
    internal let ClientVersion: ClientVersion?
    
    internal func clean() -> Tailscale.Refresh {
      let tailscale = Tailscale(version: self.Version,
                                versionUpToDate: self.ClientVersion?.runningLatest ?? false,
                                tunnelingEnabled: self.TUN,
                                backendState: self.BackendState,
                                haveNodeKey: self.HaveNodeKey,
                                health: self.Health,
                                magicDNSSuffix: self.MagicDNSSuffix,
                                currentTailnet: self.CurrentTailnet,
                                selfNodeID: .init(rawValue: self.Self.ID),
                                selfUserID: .init(rawValue: self.Self.UserID))
      let users = Dictionary<Machine.Identifier, User>(
        uniqueKeysWithValues: self.User?.map { (.init(rawValue: $0), $1) } ?? []
      )
      var machines: [Machine.Identifier: Machine] = Dictionary<Machine.Identifier, Machine>(
        uniqueKeysWithValues: self.Peer?.map { (.init(rawValue: $1.ID), $1.clean()) } ?? []
      )
      machines[.init(rawValue: self.Self.ID)] = self.Self.clean()
      return .init(tailscale: tailscale, machines: machines, users: users)
    }
  }
  
  internal struct MachineCLI: Codable, Sendable {
    internal let ID: String
    internal let PublicKey: String
    internal let HostName: String
    internal let DNSName: String
    internal let OS: String
    internal let UserID: Int
    internal let TailscaleIPs: [String]
    internal let AllowedIPs: [String]
    internal let PrimaryRoutes: [String]?
    internal let Addrs: [String]?
    internal let CurAddr: String
    internal let Relay: String
    internal let RxBytes: Int
    internal let TxBytes: Int
    internal let Created: String
    internal let LastWrite: String?
    internal let LastSeen: String?
    internal let LastHandshake: String?
    internal let Online: Bool
    internal let ExitNode: Bool
    internal let ExitNodeOption: Bool
    internal let Active: Bool
    internal let PeerAPIURL: [String]?
    internal let Capabilities: [String]?
    internal let CapMap: [String: String?]?
    internal let InNetworkMap: Bool
    internal let InMagicSock: Bool
    internal let InEngine: Bool
    internal let KeyExpiry: String?
    
    internal func clean() -> Machine {
      return .init(id: .init(rawValue: self.ID),
                   publicKey: self.PublicKey,
                   keyExpiry: self.KeyExpiry.flatMap(df.date(from:)),
                   hostname: self.HostName,
                   url: self.DNSName,
                   os: self.OS,
                   userID: self.UserID,
                   isExitNode: self.ExitNode,
                   tailscaleIPs: self.TailscaleIPs.map { Address(rawValue: $0) },
                   subnetRoutes: self.PrimaryRoutes?.map { Subnet(rawValue: $0) } ?? [],
                   region: self.Relay,
                   isActive: self.Active,
                   rxBytes: Int64(self.RxBytes),
                   txBytes: Int64(self.TxBytes),
                   created: df.date(from: self.Created)!,
                   lastWrite: self.LastWrite.flatMap(df.date(from:)),
                   lastSeen: self.LastSeen.flatMap(df.date(from:)),
                   lastHandshake: self.LastHandshake.flatMap(df.date(from:)),
                   isOnline: self.Online,
                   inNetworkMap: self.InNetworkMap,
                   inMagicSock: self.InMagicSock,
                   inEngine: self.InEngine)
    }
  }
  
  internal struct ClientVersion: Codable, Sendable {
    internal let runningLatest: Bool
    internal enum CodingKeys: String, CodingKey {
      case runningLatest = "RunningLatest"
    }
  }
}

nonisolated(unsafe) internal let df: ISO8601DateFormatter = {
  let formatter = ISO8601DateFormatter()
  formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
  return formatter
}()
