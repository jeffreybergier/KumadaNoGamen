//
//  Created by Jeffrey Bergier on 2025/01/16.
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
import Model
import Controller

public struct SettingsWindow: View {
  
  static let widthSmall:  Double = 480
  static let widthLarge:  Double = 640
  static let height: Double = 480
  
  @SettingsController private var settings
  @PresentationController private var presentation
  
  public init() { }
  
  public var body: some View {
    TabView(selection: self.$presentation.settingsTab) {
      self.tailscale
        .tabItem { Label(.tailscale, systemImage: .imageSettings) }
        .tag(Presentation.SettingsTab.tailscale)
      self.services
        .tabItem { Label(.services, systemImage: .imageServices) }
        .tag(Presentation.SettingsTab.services)
      self.scanning
        .tabItem { Label(.scanning, systemImage: .imageScanning) }
        .tag(Presentation.SettingsTab.scanning)
    }
    .formStyle(.grouped)
  }
  
  private var tailscale: some View {
    Form {
      Section(header: Text(.tailscale).font(.headline),
              footer: self.tailscaleSectionFooter)
      {
        Picker(.location, selection: self.$settings.executable.option) {
          Text(.commandLine).tag(SettingsModel.ExecutableOptions.cli)
          Text(.appStore   ).tag(SettingsModel.ExecutableOptions.app)
          Text(.custom     ).tag(SettingsModel.ExecutableOptions.custom)
        }
        if self.settings.executable.option == .custom {
          TextField(.customPath, text: self.$settings.executable.rawValue)
        }
      }
      Section(header: Text(.machineRefresh).font(.headline)) {
        Toggle(.automatic, isOn: self.$settings.machineTimer.automatic)
        TextField(.interval,
                  text: self.$settings.machineTimer.interval.map(get: { $0.description },
                                                                 set: { TimeInterval($0) ?? 0 }))
      }
      Section(header: Text(.serviceRefresh).font(.headline)) {
        Toggle(.automatic, isOn: self.$settings.statusTimer.automatic)
        TextField(.interval,
                  text: self.$settings.statusTimer.interval.map(get: { $0.description },
                                                                set: { TimeInterval($0) ?? 0 }))
      }
    }
    .frame(width: SettingsWindow.widthSmall, height: SettingsWindow.height)
  }
  
  private var services: some View {
    Table(self.$settings.services) {
      TableColumn(.name) { service in
        TextField("", text: service.name)
      }
      TableColumn(.scheme) { service in
        TextField("", text: service.scheme)
      }
      .width(64)
      TableColumn(.port) { service in
        TextField("", text: service.port.map(get: { $0.description },
                                             set: { Int($0) ?? -1 }))
      }
      .width(64)
      TableColumn(.username) { service in
        Toggle("", isOn: service.usesUsername)
          .help(.settingsServiceUser)
      }
      .width(40)
      TableColumn(.password) { service in
        Toggle("", isOn: service.usesPassword)
          .help(.settingsServicePass)
      }
      .width(40)
      TableColumn(.actions) { service in
        HStack(spacing: 4) {
          Button(.moveUp, systemImage: .imageArrowUp) {
            self.servicesMoveUp(service.wrappedValue)
          }
          Button(.moveDown, systemImage: .imageArrowDown) {
            self.servicesMoveDown(service.wrappedValue)
          }
          Button(.delete, systemImage: .imageDeleteXCircle) {
            self.settings.delete(service: service.wrappedValue)
          }
        }
        .buttonStyle(.bordered)
        .labelStyle(.iconOnly)
      }
      .width(100)
    }
    .textFieldStyle(.roundedBorder)
    .safeAreaInset(edge: .bottom) {
      HStack {
        Spacer()
        Button(.reset, systemImage: .imageReset) {
          self.settings.services = Service.default
        }
        Button(.add, systemImage: .imageAdd) {
          self.settings.services.append(.init())
        }
      }.padding([.bottom, .trailing])
    }
    .frame(width: SettingsWindow.widthLarge, height: SettingsWindow.height)
  }
  
  private var scanning: some View {
    Form {
      Section(header: Text(.netcat).font(.headline)) {
        VStack(alignment: .leading) {
          TextField(.timeout,
                    text: self.$settings.scanning.netcatTimeout.map(get: { $0.description },
                                                                    set: { Int($0) ?? 0 }))
          Text(.settingsNetcatTimeout)
            .font(.caption)
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
        }
      }
      Section(header: Text(.ping).font(.headline)) {
        VStack(alignment: .leading) {
          TextField(.count,
                    text: self.$settings.scanning.pingCount.map(get: { $0.description },
                                                                set: { Int($0) ?? 0 }))
          Text(.settingsPingCount)
            .font(.caption)
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
        }
        VStack(alignment: .leading) {
          TextField(.lossThreshold,
                    text: self.$settings.scanning.pingLoss.map(get: { $0.description },
                                                               set: { Double($0) ?? 0 }))
          Text(.settingsPingLoss)
            .font(.caption)
            .foregroundStyle(Color(nsColor: .secondaryLabelColor))
        }
      }
    }
    .frame(width: SettingsWindow.widthSmall, height: SettingsWindow.height)
  }
  
  private var tailscaleSectionFooter: Text {
    Text(self.settings.executable.stringValue)
      .font(.caption)
      .foregroundStyle(Color(nsColor: .secondaryLabelColor))
  }
  
  private func servicesMoveUp(_ service: Service) {
    guard
      let index = self.settings.services.firstIndex(of: service),
      index > 0
    else { return }
    withAnimation {
      self.settings.services.swapAt(index - 1, index)
    }
  }
  
  private func servicesMoveDown(_ service: Service) {
    guard
      let index = self.settings.services.firstIndex(of: service),
      index < self.settings.services.count - 1
    else { return }
    withAnimation {
      self.settings.services.swapAt(index, index + 1)
    }
  }
}
