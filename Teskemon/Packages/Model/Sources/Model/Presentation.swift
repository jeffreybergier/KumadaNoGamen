//
//  Created by Jeffrey Bergier on 2025/01/25.
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

import Foundation

public struct PresentationControllerValue: Codable {
  public var selection = Set<Machine.Identifier>()
  public var infoPanel: PresentationInfoPanelInput = .init()
  public var showsPasswords = false
  public init() { }
}

public struct PresentationInfoPanelInput: Codable {  
  public var isPresented: Bool
  public var currentTab: Int
  public var selection: [Machine.Identifier]
  public init(tab: Int = 0, _ selection: Set<Machine.Identifier> = []) {
    self.isPresented = true
    self.currentTab = tab
    self.selection = selection.sorted(by: { $0.rawValue < $1.rawValue })
  }
  public init() {
    self.isPresented = false
    self.currentTab = 0
    self.selection = []
  }
}
