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
  
  @SettingsController private var settings
  @JSBSceneStorage("ControllerValue") private var model = MachineTableModel()
  
  public init() {}
  
  public var wrappedValue: MachineTableModel {
    get { self.model }
    nonmutating set { self.model = newValue }
  }
  
  public var projectedValue: Binding<MachineTableModel> {
    return self.$model
  }
  
  public func resetData() {
    self.model = .init()
  }
  
  public func updateMachines() async throws {
    NSLog("[START] Controller.updateMachines()")
    self.model = try await Process.tableModel(with: self.settings.executableString)
    NSLog("[END  ] Controller.updateMachines()")
  }
  
  public func updateServices() async throws {
    NSLog("[START] Controller.updateServices()")
    try await Process.status(for: self.settings.services,
                             on: self.model.selectedMachines(),
                             bind: self.$model.status)
    NSLog("[END  ] Controller.updateServices()")
  }
}

extension TableController {
}
