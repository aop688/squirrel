//
//  SquirrelApplicationDelegate.swift
//  Squirrel
//
//  Created by Leo Liu on 5/6/24.
//

import AppKit

final class SquirrelApplicationDelegate: NSObject, NSApplicationDelegate {
  let rimeAPI: RimeApi_stdbool = rime_get_api_stdbool().pointee
  var config: SquirrelConfig?
  var panel: SquirrelPanel?

  func applicationWillFinishLaunching(_ notification: Notification) {
    panel = SquirrelPanel(position: .zero)
    addObservers()
  }

  func applicationWillTerminate(_ notification: Notification) {
    // swiftlint:disable:next notification_center_detachment
    NotificationCenter.default.removeObserver(self)
    DistributedNotificationCenter.default().removeObserver(self)
    panel?.hide()
  }

  func deploy() {
    print("Start maintenance...")
    self.shutdownRime()
    self.startRime(fullCheck: true)
    self.loadSettings()
  }

  func openRimeFolder() {
    NSWorkspace.shared.open(SquirrelApp.userDir)
  }

  func setupRime() {
    createDirIfNotExist(path: SquirrelApp.userDir)
    createDirIfNotExist(path: SquirrelApp.logDir)
    // swiftlint:disable identifier_name
    let notification_handler: @convention(c) (UnsafeMutableRawPointer?, RimeSessionId, UnsafePointer<CChar>?, UnsafePointer<CChar>?) -> Void = notificationHandler
    let context_object = Unmanaged.passUnretained(self).toOpaque()
    // swiftlint:enable identifier_name
    rimeAPI.set_notification_handler(notification_handler, context_object)

    var squirrelTraits = RimeTraits.rimeStructInit()
    squirrelTraits.setCString(Bundle.main.sharedSupportPath!, to: \.shared_data_dir)
    squirrelTraits.setCString(SquirrelApp.userDir.path(), to: \.user_data_dir)
    squirrelTraits.setCString(SquirrelApp.logDir.path(), to: \.log_dir)
    squirrelTraits.setCString("Squirrel", to: \.distribution_code_name)
    squirrelTraits.setCString("鼠鬚管", to: \.distribution_name)
    squirrelTraits.setCString(Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as? String ?? "Unknown", to: \.distribution_version)
    squirrelTraits.setCString("rime.squirrel", to: \.app_name)
    rimeAPI.setup(&squirrelTraits)
  }

  func startRime(fullCheck: Bool) {
    print("Initializing la rime...")
    rimeAPI.initialize(nil)
    // check for configuration updates
    if rimeAPI.start_maintenance(fullCheck) {
      // update squirrel config
      // print("[DEBUG] maintenance suceeds")
      _ = rimeAPI.deploy_config_file("squirrel.yaml", "config_version")
    } else {
      // print("[DEBUG] maintenance fails")
    }
  }

  func loadSettings() {
    config = SquirrelConfig()
    if !config!.openBaseConfig() {
      return
    }

    if let panel = panel, let config = self.config {
      panel.load(config: config, forDarkMode: false)
      panel.load(config: config, forDarkMode: true)
    }
  }

  // add an awakeFromNib item so that we can set the action method.  Note that
  // any menuItems without an action will be disabled when displayed in the Text
  // Input Menu.
  func addObservers() {
    let center = NSWorkspace.shared.notificationCenter
    center.addObserver(forName: NSWorkspace.willPowerOffNotification, object: nil, queue: nil, using: workspaceWillPowerOff)

    let notifCenter = DistributedNotificationCenter.default()
    notifCenter.addObserver(forName: .init("SquirrelReloadNotification"), object: nil, queue: nil, using: rimeNeedsReload)
  }

  func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
    print("Squirrel is quitting.")
    rimeAPI.cleanup_all_sessions()
    return .terminateNow
  }

}

private func notificationHandler(contextObject: UnsafeMutableRawPointer?, sessionId: RimeSessionId, messageTypeC: UnsafePointer<CChar>?, messageValueC: UnsafePointer<CChar>?) {
  _ = contextObject
  _ = sessionId
  _ = messageTypeC
  _ = messageValueC
  // All notifications removed in lite version
}

private extension SquirrelApplicationDelegate {
  func shutdownRime() {
    config?.close()
    rimeAPI.finalize()
  }

  func workspaceWillPowerOff(_: Notification) {
    print("Finalizing before logging out.")
    self.shutdownRime()
  }

  func rimeNeedsReload(_: Notification) {
    print("Reloading rime on demand.")
    self.deploy()
  }

  func createDirIfNotExist(path: URL) {
    let fileManager = FileManager.default
    if !fileManager.fileExists(atPath: path.path()) {
      do {
        try fileManager.createDirectory(at: path, withIntermediateDirectories: true)
      } catch {
        print("Error creating user data directory: \(path.path())")
      }
    }
  }
}

extension NSApplication {
  var squirrelAppDelegate: SquirrelApplicationDelegate {
    guard let delegate = self.delegate as? SquirrelApplicationDelegate else {
      fatalError("Expected SquirrelApplicationDelegate as app delegate")
    }
    return delegate
  }
}
