/*
 * Copyright (c) 2010-2023 Belledonne Communications SARL.
 *
 * This file is part of linphone-iphone
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import SwiftUI
import UniformTypeIdentifiers

struct SettingsAdvancedFragment: View {
	@ObservedObject var settingsViewModel: SettingsViewModel
	
	@Environment(\.dismiss) var dismiss
	
	@State var audioDevicesIsOpen: Bool = false
	
	@FocusState var isDeviceIdFocused: Bool
	@FocusState var isRemoteProvisioningUrlFocused: Bool
	
	var body: some View {
		ZStack {
			VStack(spacing: 1) {
				Rectangle()
					.foregroundColor(Color.orangeMain500)
					.edgesIgnoringSafeArea(.top)
					.frame(height: 0)
				
				HStack {
					Image("caret-left")
						.renderingMode(.template)
						.resizable()
						.foregroundStyle(Color.orangeMain500)
						.frame(width: 25, height: 25, alignment: .leading)
						.padding(.all, 10)
						.padding(.top, 4)
						.padding(.leading, -10)
						.onTapGesture {
							dismiss()
						}
					
					Text("settings_advanced_title")
						.default_text_style_orange_800(styleSize: 16)
						.frame(maxWidth: .infinity, alignment: .leading)
						.padding(.top, 4)
						.lineLimit(1)
					
					Spacer()
				}
				.frame(maxWidth: .infinity)
				.frame(height: 50)
				.padding(.horizontal)
				.padding(.bottom, 4)
				.background(.white)
				
				ScrollView {
					VStack(spacing: 0) {
						VStack(spacing: 30) {
                            Socks5SettingsEditorView()

							VStack(alignment: .leading) {
								Text("settings_advanced_device_id")
									.default_text_style_700(styleSize: 15)
									.padding(.bottom, -5)
								
								TextField("settings_advanced_device_id_hint", text: $settingsViewModel.deviceId)
									.default_text_style(styleSize: 15)
									.frame(height: 25)
									.padding(.horizontal, 20)
									.padding(.vertical, 15)
									.cornerRadius(60)
									.overlay(
										RoundedRectangle(cornerRadius: 60)
											.inset(by: 0.5)
											.stroke(isDeviceIdFocused ? Color.orangeMain500 : Color.gray200, lineWidth: 1)
									)
									.focused($isDeviceIdFocused)
							}
							
							VStack(alignment: .leading) {
								Text("settings_advanced_remote_provisioning_url")
									.default_text_style_700(styleSize: 15)
									.padding(.bottom, -5)
								
								TextField("settings_advanced_remote_provisioning_url", text: $settingsViewModel.remoteProvisioningUrl)
									.default_text_style(styleSize: 15)
									.frame(height: 25)
									.padding(.horizontal, 20)
									.padding(.vertical, 15)
									.cornerRadius(60)
									.overlay(
										RoundedRectangle(cornerRadius: 60)
											.inset(by: 0.5)
											.stroke(isRemoteProvisioningUrlFocused ? Color.orangeMain500 : Color.gray200, lineWidth: 1)
									)
									.focused($isRemoteProvisioningUrlFocused)
							}
							
							HStack {
								Spacer()
								
								Button(
									action: {
										settingsViewModel.downloadAndApplyRemoteProvisioning()
									}, label: {
										Text("settings_advanced_download_apply_remote_provisioning")
											.default_text_style_white_600(styleSize: 15)
									}
								)
								.padding(.horizontal, 20)
								.padding(.vertical, 10)
								.background(settingsViewModel.remoteProvisioningUrl.isEmpty ? Color.orangeMain100 : Color.orangeMain500)
								.cornerRadius(60)
								.disabled(settingsViewModel.remoteProvisioningUrl.isEmpty)
							}
						}
						.padding(.vertical, 20)
						.padding(.horizontal, 20)
						.background(.white)
						.cornerRadius(15)
						.background(Color.gray100)
						
						/*
						HStack(alignment: .center) {
							Text("settings_advanced_audio_devices_title")
								.default_text_style_800(styleSize: 18)
								.frame(maxWidth: .infinity, alignment: .leading)
							
							Spacer()
							
							Image(audioDevicesIsOpen ? "caret-up" : "caret-down")
								.renderingMode(.template)
								.resizable()
								.foregroundStyle(Color.grayMain2c600)
								.frame(width: 25, height: 25, alignment: .leading)
								.padding(.all, 10)
						}
						.padding(.vertical, 10)
						.padding(.horizontal, 20)
						.background(Color.gray100)
						.onTapGesture {
							withAnimation {
								audioDevicesIsOpen.toggle()
							}
						}
						
						if audioDevicesIsOpen {
							VStack(spacing: 0) {
								VStack(spacing: 30) {
									VStack(alignment: .leading) {
										Text("settings_advanced_input_audio_device_title")
											.default_text_style_700(styleSize: 15)
											.padding(.bottom, -5)
										
										Menu {
											ForEach(settingsViewModel.inputAudioDeviceLabels, id: \.self) { inputAudioDevice in
												Button(inputAudioDevice) {
													if let inputAudioDeviceIndexTmp = settingsViewModel.inputAudioDeviceLabels.firstIndex(of: inputAudioDevice) {
														settingsViewModel.setInputAudioDevice(index: inputAudioDeviceIndexTmp)
													}
												}
											}
										} label: {
											Text(settingsViewModel.inputAudioDeviceIndex < settingsViewModel.inputAudioDeviceLabels.count
												 ? settingsViewModel.inputAudioDeviceLabels[settingsViewModel.inputAudioDeviceIndex] : "")
												.default_text_style(styleSize: 15)
												.frame(maxWidth: .infinity, alignment: .leading)
											Image("caret-down")
												.renderingMode(.template)
												.resizable()
												.foregroundStyle(Color.grayMain2c500)
												.frame(width: 20, height: 20)
										}
										.frame(height: 25)
										.padding(.horizontal, 20)
										.padding(.vertical, 15)
										.cornerRadius(60)
										.overlay(
											RoundedRectangle(cornerRadius: 60)
												.inset(by: 0.5)
												.stroke(Color.gray200, lineWidth: 1)
										)
									}
									
									VStack(alignment: .leading) {
										Text("settings_advanced_output_audio_device_title")
											.default_text_style_700(styleSize: 15)
											.padding(.bottom, -5)
										
										Menu {
											ForEach(settingsViewModel.outputAudioDeviceLabels, id: \.self) { outputAudioDevice in
												Button(outputAudioDevice) {
													if let outputAudioDeviceIndexTmp = settingsViewModel.outputAudioDeviceLabels.firstIndex(of: outputAudioDevice) {
														settingsViewModel.setOutputAudioDevice(index: outputAudioDeviceIndexTmp)
													}
												}
											}
										} label: {
											Text(settingsViewModel.outputAudioDeviceIndex < settingsViewModel.outputAudioDeviceLabels.count
												 ? settingsViewModel.outputAudioDeviceLabels[settingsViewModel.outputAudioDeviceIndex] : "")
												.default_text_style(styleSize: 15)
												.frame(maxWidth: .infinity, alignment: .leading)
											Image("caret-down")
												.renderingMode(.template)
												.resizable()
												.foregroundStyle(Color.grayMain2c500)
												.frame(width: 20, height: 20)
										}
										.frame(height: 25)
										.padding(.horizontal, 20)
										.padding(.vertical, 15)
										.cornerRadius(60)
										.overlay(
											RoundedRectangle(cornerRadius: 60)
												.inset(by: 0.5)
												.stroke(Color.gray200, lineWidth: 1)
										)
									}
								}
								.padding(.vertical, 30)
								.padding(.horizontal, 20)
							}
							.background(.white)
							.cornerRadius(15)
						 	.padding(.horizontal, 20)
							.zIndex(-1)
							.transition(.move(edge: .top))
						 	.background(Color.gray100)
						}
						*/
					}
					.padding(.vertical, 20)
					.padding(.horizontal, 20)
					.frame(maxWidth: SharedMainViewModel.shared.maxWidth)
					.frame(maxWidth: .infinity)
				}
				.background(Color.gray100)
			}
			.background(Color.gray100)
		}
		.navigationTitle("")
		.navigationBarHidden(true)
	}
}

struct SettingsToggleWidget: View {
	var title: String
	var subtitle: String
	@Binding var isOn: Bool
	
	var body: some View {
		HStack {
			VStack(alignment: .leading, spacing: 2) {
				Text(title)
					.default_text_style_700(styleSize: 15)
				if !subtitle.isEmpty {
					Text(subtitle)
						.foregroundColor(Color.grayMain2c500)
						.default_text_style(styleSize: 14)
				}
			}
			.layoutPriority(1)
			
			Toggle(isOn: $isOn) {
				EmptyView()
			}
			.toggleStyle(SwitchToggleStyle())
		}
	}
}

private struct Socks5SettingsEditorView: View {
 @State private var enabled = false
 @State private var host = ""
 @State private var port = ""
 @State private var username = ""
 @State private var password = ""
 @State private var status = ""
 @State private var busy = false
 var body: some View {
  VStack(alignment: .leading, spacing: 12) {
   Text("SOCKS5 — experimental audio transport").font(.headline)
   Toggle("Require SOCKS5 (never fall back to direct)", isOn: $enabled)
   TextField("Proxy numeric IP (local or remote)", text: $host)
    .textInputAutocapitalization(.never).autocorrectionDisabled()
   TextField("Proxy TCP port", text: $port).keyboardType(.numberPad)
   TextField("Username (empty for no authentication)", text: $username)
    .textInputAutocapitalization(.never).autocorrectionDisabled()
   SecureField("Password", text: $password)
   Text("Requires a custom SDK, SIP/UDP with numeric server addresses, and an SBC/PBX with symmetric RTP. TCP/TLS, video, ICE/STUN/TURN and extension message fetching are not supported. A SOCKS5 connection alone does not establish public media reachability.")
    .font(.footnote)
   Button("Save and restart Core", action: apply).disabled(busy)
   if !status.isEmpty { Text(status).font(.footnote).accessibilityIdentifier("socks5Status") }
  }
  .onAppear {
   CoreContext.shared.doOnCoreQueue { core in
    guard let config = core.config else { return }
    let preferences = try? Socks5Settings.preferences()
    let required = (preferences?.bool(forKey: "socks5.required") ?? false) || config.getBool(section: "socks5", key: "required", defaultValue: false)
    let address: String? = preferences?.string(forKey: "socks5.host") ?? config.getString(section: "socks5", key: "host", defaultString: "")
    let number = preferences?.object(forKey: "socks5.port") == nil ? config.getInt(section: "socks5", key: "port", defaultValue: 0) : (preferences?.integer(forKey: "socks5.port") ?? 0)
    let secret = try? Socks5Settings.readCredentials()
    DispatchQueue.main.async {
     enabled = required; host = address ?? ""; port = number == 0 ? "" : String(number)
     username = secret?.username ?? ""; password = secret?.password ?? ""
#if !LINPHONE_SOCKS5_SDK
     status = "Official SDK: enabling SOCKS5 will block Core startup until the local fork is connected."
#endif
    }
   }
  }
 }
 private func apply() {
  guard !enabled || (!host.isEmpty && !host.contains("\0") && (1...65535).contains(Int(port) ?? 0)) else {
   status = "Enter a proxy IP and TCP port in 1–65535."; return
  }
  let require = enabled, address = host, number = Int(port) ?? 0, user = username, secret = password
  busy = true
  CoreContext.shared.doOnCoreQueue { core in
   do {
    guard core.callsNb == 0 else { throw CoreError("End all calls before changing the proxy.") }
    core.stop()
    guard let config = core.config else { throw CoreError("Core configuration unavailable.") }
    let preferences = try Socks5Settings.preferences()
    preferences.set(require, forKey: "socks5.required")
    preferences.set(address, forKey: "socks5.host")
    preferences.set(number, forKey: "socks5.port")
    config.setBool(section: "socks5", key: "required", value: require)
    config.setString(section: "socks5", key: "host", value: address)
    config.setInt(section: "socks5", key: "port", value: number)
    try config.sync()
    if require { try Socks5Settings.saveCredentials(username: user, password: secret) }
    else { Socks5Settings.removeCredentials() }
    try core.startWithSocks5Policy()
    DispatchQueue.main.async { busy = false; status = require ? "Proxy policy applied. Registration and bidirectional audio still need verification." : "Proxy disabled explicitly." }
   } catch {
    let message = (error as? CoreError)?.message ?? "Proxy setup/start failed. Core remains stopped; no direct fallback."
    DispatchQueue.main.async { busy = false; status = message }
   }
  }
 }
}
