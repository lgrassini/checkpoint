import Foundation
import ServiceManagement

enum LoginItemStatus: Equatable {
    case enabled
    case notRegistered
    /// Registered, but the user still has to approve it in
    /// System Settings > General > Login Items.
    case requiresApproval
    case notFound
}

/// Abstracts SMAppService so LaunchAtLogin's logic is unit-testable.
protocol LoginItemService {
    var status: LoginItemStatus { get }
    func register() throws
    func unregister() throws
}

struct SMAppServiceLoginItem: LoginItemService {
    private var service: SMAppService { .mainApp }

    var status: LoginItemStatus {
        switch service.status {
        case .enabled: .enabled
        case .requiresApproval: .requiresApproval
        case .notFound: .notFound
        case .notRegistered: .notRegistered
        @unknown default: .notRegistered
        }
    }

    func register() throws { try service.register() }
    func unregister() throws { try service.unregister() }
}

/// The system's login-item registration is the source of truth (the user can
/// also change it in System Settings), so nothing here is persisted to
/// UserDefaults: state is always re-read from the service after any change.
final class LaunchAtLogin: ObservableObject {
    @Published private(set) var status: LoginItemStatus
    @Published private(set) var errorMessage: String?

    private let service: LoginItemService

    init(service: LoginItemService = SMAppServiceLoginItem()) {
        self.service = service
        status = service.status
    }

    var isEnabled: Bool { status == .enabled }
    var needsApproval: Bool { status == .requiresApproval }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        status = service.status
    }

    /// Re-reads the system state, e.g. when the Settings window is shown,
    /// in case it was changed in System Settings in the meantime.
    func refresh() {
        status = service.status
    }
}
