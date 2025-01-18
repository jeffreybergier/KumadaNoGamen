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

import SwiftUI
import Model
import Controller

internal struct MachineInfoWindow: View {
  
  @SceneStorage("MachineInfoSelectedTab") private var currentTab = 0
  @Environment(\.dismiss) private var dismiss
  
  private let ids: [Machine.Identifier]
  
  internal init(ids: Set<Machine.Identifier>) {
    self.ids = ids.sorted(by: { $0.rawValue < $1.rawValue })
  }
  
  internal var body: some View {
    NavigationStack {
      TabView(selection: self.$currentTab) {
        self.machineInfo.tabItem {
          Label("Info", systemImage: "info.circle")
        }.tag(0)
        self.customNames.tabItem {
          Label("Names", systemImage: "person")
        }.tag(1)
        self.passwords.tabItem {
          Label("Passwords", systemImage: "ellipsis.rectangle")
        }.tag(2)
      }
      .navigationTitle("Machine Info")
      .padding([.top])
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Done", action: self.dismiss.callAsFunction)
        }
      }
    }
  }
  
  private var machineInfo: some View {
    Text("Machine Info")
  }
  
  private var customNames: some View {
    Text("Custom Names")
  }
  
  private var passwords: some View {
    Text("Passwords")
  }
  
}
