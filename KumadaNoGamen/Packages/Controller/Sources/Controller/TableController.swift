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

import SwiftUI
import Model
import Umbrella

@MainActor
@propertyWrapper
public struct TableController: DynamicProperty {
  
  @JSBSceneStorage("ControllerValue") private var storage = TableModel()
  @AppStorage("TailscaleLocation") private var location = "/Applications/Tailscale.app/Contents/MacOS/Tailscale"
  //  = "/usr/local/bin/tailscale"
  @Services private var services
  
  public init() {}
  
  public var wrappedValue: TableModel {
    get { self.storage }
    nonmutating set { self.storage = newValue }
  }
  
  public func resetData() {
    self.storage = .init()
  }
  
  public func updateMachines() async throws {
    NSLog("Controller: updateMachines")
    self.storage = try await type(of: self).getTailscale(self.location)
  }
  
  public func updateServices() async throws {
    NSLog("Controller: updateServices")
    self.storage.services = [:]
    Task {
      try await type(of: self).getStatus(for: self.services,
                                         on: self.storage.allMachines,
                                         bind: self.$storage.services)
    }
  }
}

extension TableController {
  
  internal static func getTailscale(_ location: String) async throws -> TableModel {
    let data = try await Process.execute(arguments: [location, "status", "--json"]).stdOut
    let model = try TableModel(data: data)
    return model
  }
  
  internal static func getStatus(for services: [Service],
                                 on  machines: [Machine],
                                 bind: Binding<[MachineIdentifier: [Service: Service.Status]]>,
                                 timeout: Int = 3)
  async throws
  {
    // Iterate over every machine
    for machine in machines {
      // Prepare the binding to accept values for this machine
      let id = machine.id
      if bind.wrappedValue[id] == nil { bind.wrappedValue[id] = [:] }
      // Mark status as processing while network activity happens
      for service in services {
        bind.wrappedValue[id]![service] = .processing
      }
      let machineResults = try await withThrowingTaskGroup(of: [ServiceStatusReturn].self) { group in
        group.addTask {
          var output = [ServiceStatusReturn]()
          // Iterate over every service
          for service in services {
            // Perform network request
            let arguments: [String] = [
              "/usr/bin/nc",
              "-zv",
              "-G \(timeout)",
              "-w \(timeout)",
              machine.url,
              "\(service.port)"
            ]
            let result = try await Process.execute(arguments: arguments)
            // Not sure why Netcat puts the results in standard error, but it does
            let resultString = String(data: result.errOut, encoding: .utf8)!
            // Check result and update status
            if resultString.hasSuffix("succeeded!\n") {
              output.append(.init(status: .online, service: service, id: id))
            } else if resultString.hasSuffix("refused\n") {
              output.append(.init(status: .offline, service: service, id: id))
            } else if resultString.hasSuffix("Operation timed out\n") {
              output.append(.init(status: .error, service: service, id: id))
            } else {
              assertionFailure()
              output.append(.init(status: .error, service: service, id: id))
            }
          }
          return output
        }
        var output = [ServiceStatusReturn]()
        for try await result in group {
          output.append(contentsOf: result)
        }
        return output
      }
      for machineResult in machineResults {
        bind.wrappedValue[machineResult.id]![machineResult.service] = machineResult.status
      }
    }
  }
}

internal struct ServiceStatusReturn {
  internal let status: Service.Status
  internal let service: Service
  internal let id: MachineIdentifier
}
