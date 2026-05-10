import Foundation
import Sentry

enum Telemetry {

  static let crashReportingEnabledKey = "crashReportingEnabled"

  static func registerDefaults() {
    UserDefaults.standard.register(defaults: [crashReportingEnabledKey: true])
  }

  static func startIfEnabled() {
    let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String ?? ""
    guard !dsn.isEmpty else { return }
    guard UserDefaults.standard.bool(forKey: crashReportingEnabledKey) else { return }
    SentrySDK.start { options in
      options.dsn = dsn
      options.sendDefaultPii = false
      options.tracesSampleRate = 1.0
      options.beforeSend = { event in
        event.user = nil
        return event
      }
      #if DEBUG
      options.debug = true
      #endif
    }
  }

  static func applySettingChange(enabled: Bool) {
    if enabled {
      startIfEnabled()
    } else {
      SentrySDK.close()
    }
  }
}
