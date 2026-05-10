import Foundation
import Sentry

enum Telemetry {

  static func startIfEnabled() {
    let dsn = Bundle.main.object(forInfoDictionaryKey: "SentryDSN") as? String ?? ""
    guard !dsn.isEmpty else { return }
    guard UserDefaults.standard.bool(forKey: Preference.crashReportingEnabled) else { return }
    SentrySDK.start { options in
      options.dsn = dsn
      options.sendDefaultPii = false
      options.tracesSampleRate = 1.0
      // Apple's recommended macOS practice: crash on uncaught NSExceptions
      // rather than letting Cocoa frameworks continue in a corrupt state.
      options.enableUncaughtNSExceptionReporting = true
      // SIGTERM precedes SIGKILL for OS-driven kills (CPU/disk/watchdog/
      // app updates) — surface those rather than silently disappearing.
      options.enableSigtermReporting = true
      // Capture every thread's stack on events so AX deadlocks/hangs show
      // who else was running, not just the main thread.
      options.attachAllThreads = true
      // Forward Apple's MetricKit diagnostics (CPU/hang/disk-write
      // exceptions). Free signal — Apple already collects it.
      options.enableMetricKit = true
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
