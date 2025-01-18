//
//  Created by Jeffrey Bergier on 2025/01/18.
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

public struct SettingsModel: Codable, Hashable, Sendable {
  
  public var services = Service.default
  public var timeout = 5
  public var batchSize = 8
  public var executable = Executable.cli
  public var executableRaw: String = ""
  
  public var executableString: String {
    switch self.executable {
    case .cli:    return "/usr/local/bin/tailscale"
    case .app:    return "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
    case .custom: return self.executableRaw
    }
  }
  
  public mutating func delete(service: Service) {
    guard let index = self.services.firstIndex(where: { $0.id == service.id }) else { return }
    self.services.remove(at: index)
  }
  
  public init () {}
  
}

public enum Executable: CaseIterable, Codable, Hashable, Sendable {
  case cli
  case app
  case custom
}
