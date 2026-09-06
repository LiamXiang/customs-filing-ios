import SwiftUI

@main
struct FilingApp: App {
    @StateObject private var lockState = LockState()
    var body: some Scene {
        WindowGroup {
            if lockState.lockEnabled && !lockState.unlocked {
                PinLockView { lockState.unlocked = true }
            } else {
                MainTabView()
            }
        }
    }
}

final class LockState: ObservableObject {
    @Published var unlocked = false
    var lockEnabled: Bool {
        UserDefaults.standard.bool(forKey: "lock_enabled")
    }
}
