//
//  Created by Jeffrey Bergier on 15/1/18.
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
import View

@main
struct TeskemonApp: App {
  
  @Environment(\.openWindow) private var window
  
  var body: some Scene {
    WindowGroup {
      MachineWindow()
    }
    .commands {
      CommandGroup(replacing: .appInfo) {
        Button(.aboutTeskemon) {
          self.window(id: AboutWindow.id, value: AboutWindow.id)
        }
      }
    }
    Settings {
      SettingsWindow()
    }
    WindowGroup(id: AboutWindow.id, for: String.self) { _ in
      AboutWindow()
    }
    .windowResizability(.contentSize)
  }
}
